/*
 * %CopyrightBegin%
 *
 * Copyright Ericsson AB 2010-2015. All Rights Reserved.
 *
 * The contents of this file are subject to the Erlang Public License,
 * Version 1.1, (the "License"); you may not use this file except in
 * compliance with the License. You should have received a copy of the
 * Erlang Public License along with this software. If not, it can be
 * retrieved online at http://www.erlang.org/.
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
 * the License for the specific language governing rights and limitations
 * under the License.
 *
 * %CopyrightEnd%
 */

/*
 * Description: Epiphany implementation of the ethread library
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include "sys.h"

#define ETHR_CHILD_WAIT_SPIN_COUNT 4000

#define ETHREAD_IMPL__

#include "ethread.h"
#include "ethr_internal.h"

#ifndef ETHR_HAVE_ETHREAD_DEFINES
#error Missing configure defines
#endif

void
ethr_compiler_barrier(void)
{
    ETHR_MEMBAR(0);
}

int
ethr_init(ethr_init_data *id)
{
    return 0;
}

int
ethr_late_init(ethr_late_init_data *id)
{
    return 0;
}

int
ethr_thr_create(ethr_tid *tid, void * (*func)(void *), void *arg,
		ethr_thr_opts *opts)
{
    EPIPHANY_STUB_FUN();
}

int
ethr_thr_join(ethr_tid tid, void **res)
{
    EPIPHANY_STUB_FUN();
}

int
ethr_thr_detach(ethr_tid tid)
{
    EPIPHANY_STUB_FUN();
}

void
ethr_thr_exit(void *res)
{
    EPIPHANY_STUB_FUN();
}

ethr_tid
ethr_self(void)
{
    EPIPHANY_STUB_FUN();
}

int
ethr_equal_tids(ethr_tid tid1, ethr_tid tid2)
{
    EPIPHANY_STUB_FUN();
}


/*
 * Thread specific events
 */

ethr_ts_event *
ethr_get_ts_event(void)
{
    EPIPHANY_STUB_FUN();
}

void
ethr_leave_ts_event(ethr_ts_event *tsep)
{
    EPIPHANY_STUB_FUN();
}

/*
 * Thread specific data
 */

int
ethr_tsd_key_create(ethr_tsd_key *keyp, char *keyname)
{
    EPIPHANY_STUB_FUN();
}

int
ethr_tsd_key_delete(ethr_tsd_key key)
{
    EPIPHANY_STUB_FUN();
}

int
ethr_tsd_set(ethr_tsd_key key, void *value)
{
    EPIPHANY_STUB_FUN();
}

void *
ethr_tsd_get(ethr_tsd_key key)
{
    EPIPHANY_STUB_FUN();
}

/* internal exports */

int
ethr_set_tse__(ethr_ts_event *tsep)
{
    EPIPHANY_STUB_FUN();
}

ethr_ts_event
*ethr_get_tse__(void)
{
    EPIPHANY_STUB_FUN();
}

/*
 * Signal functions
 */

#if ETHR_HAVE_ETHR_SIG_FUNCS

int ethr_sigmask(int how, const sigset_t *set, sigset_t *oset)
{
    EPIPHANY_STUB_FUN();
}

int ethr_sigwait(const sigset_t *set, int *sig)
{
    EPIPHANY_STUB_FUN();
}

#endif /* #if ETHR_HAVE_ETHR_SIG_FUNCS */

ETHR_IMPL_NORETURN__
ethr_abort__(void)
{
    abort();
}

/* Atomics */
void
ethr_native_atomic32_init(ethr_native_atomic32_t *var, ethr_sint32_t val)
{
    EPIPHANY_STUB_FUN();
}

ethr_sint32_t
ethr_native_atomic32_cmpxchg(ethr_native_atomic32_t *var,
			     ethr_sint32_t val,
			     ethr_sint32_t old_val)
{
    EPIPHANY_STUB_FUN();
}

/* Spinlocks */
#include "epiphany.h"

#define MUTEX_COUNT 8
#define MUTEX_UNLOCKED 0
#define MUTEX_UNUSED -1
static EPIPHANY_SRAM_DATA e_mutex_t mutexes[MUTEX_COUNT] = {
    [0] = MUTEX_UNLOCKED,
    [1 ... MUTEX_COUNT-1] = MUTEX_UNUSED,
};

static int
allocate_on_core(char row, char col)
{
    e_mutex_t *core_mutexes = e_get_global_address(row, col, mutexes);
    int i;
    e_mutex_lock(row, col, mutexes + 0);
    for (i = 1; i < MUTEX_COUNT; i++) {
	if (core_mutexes[i] == MUTEX_UNUSED) {
	    e_mutex_init(row, col, mutexes + i, NULL);
	    e_mutex_unlock(row, col, mutexes + 0);
	    return i;
	}
    }
    e_mutex_unlock(row, col, mutexes + 0);
    return -1;
}

void
ethr_native_spinlock_init(ethr_native_spinlock_t *lock)
{
    ethr_native_spinlock_t lockv;
    e_coreid_t me = e_get_coreid();
    unsigned myrow, row, mycol, col;
    int i;
    /* It is unnecessary to use all this allocation if the address is in SRAM
     * anyway */
    ASSERT(epiphany_in_dram(lock));

    e_coords_from_coreid(me, &myrow, &mycol);
    col = mycol;
    row = myrow;
    if ((i = allocate_on_core(myrow, mycol)) == -1) {
	struct workgroup_coords origin = epiphany_workgroup_origin();
	struct workgroup_dimens dimens = epiphany_workgroup_dimens();
	for (row = origin.row; row < origin.row + dimens.rows && i == -1; row++) {
	    for (col = origin.col; col < origin.col + dimens.cols && i == -1; col++) {
		if (col == mycol && row == myrow) continue;
		i = allocate_on_core(row, col);
	    }
	}
    }

    if (i == -1) {
	ASSERT(!"Out of mutexes!");
	erl_exit(1, "Out of mutexes!");
    }

    lockv.row = row;
    lockv.col = col;
    lockv.ix = (unsigned short)i;

    *lock = lockv;
}

int
ethr_native_spinlock_destroy(ethr_native_spinlock_t *lock)
{
    ethr_native_spinlock_t lockv = *lock;
    volatile e_mutex_t *mtx = e_get_global_address(lockv.row, lockv.col, mutexes + lockv.ix);
    ASSERT(*mtx == MUTEX_UNLOCKED);
    *mtx = MUTEX_UNUSED;
    return 0;
}

void
ethr_native_spin_unlock(ethr_native_spinlock_t *lock)
{
    ethr_native_spinlock_t lockv = *lock;
#if defined(DEBUG) || defined(ETHR_DEBUG)
    volatile e_mutex_t *mtx = e_get_global_address(lockv.row, lockv.col, mutexes + lockv.ix);
    e_coreid_t me = e_get_coreid();
    ASSERT(*((volatile e_mutex_t*)mtx) == me);
#endif
    e_mutex_unlock(lockv.row, lockv.col, mutexes + lockv.ix);
}

int
ethr_native_spin_trylock(ethr_native_spinlock_t *lock)
{
    ethr_native_spinlock_t lockv = *lock;
#if defined(DEBUG) || defined(ETHR_DEBUG)
    volatile e_mutex_t *mtx = e_get_global_address(lockv.row, lockv.col, mutexes + lockv.ix);
    ASSERT(*((volatile e_mutex_t*)mtx) != MUTEX_UNUSED);
#endif
    return e_mutex_trylock(lockv.row, lockv.col, mutexes + lockv.ix);
}

int
ethr_native_spin_is_locked(ethr_native_spinlock_t *lock)
{
    ethr_native_spinlock_t lockv = *lock;
    volatile e_mutex_t *mtx = e_get_global_address(lockv.row, lockv.col, mutexes + lockv.ix);
    ASSERT(*((volatile e_mutex_t*)mtx) != MUTEX_UNUSED);
    return *mtx == MUTEX_UNLOCKED;
}

void
ethr_native_spin_lock(ethr_native_spinlock_t *lock)
{
    ethr_native_spinlock_t lockv = *lock;
#if defined(DEBUG) || defined(ETHR_DEBUG)
    volatile e_mutex_t *mtx = e_get_global_address(lockv.row, lockv.col, mutexes + lockv.ix);
    ASSERT(*((volatile e_mutex_t*)mtx) != MUTEX_UNUSED);
#endif
    e_mutex_lock(lockv.row, lockv.col, mutexes + lockv.ix);
}