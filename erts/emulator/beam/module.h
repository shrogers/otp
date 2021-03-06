/*
 * %CopyrightBegin%
 *
 * Copyright Ericsson AB 1996-2013. All Rights Reserved.
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

#ifndef __MODULE_H__
#define __MODULE_H__

#ifndef __INDEX_H__
#include "index.h"
#endif

#include "slave.h"

struct SLAVE_SHARED_DATA erl_module_instance {
    BeamInstr* code;
    int code_length;		/* Length of loaded code in bytes. */
    unsigned catches;
    struct erl_module_nif* nif;
    int num_breakpoints;
    int num_traced_exports;
};

typedef struct SLAVE_SHARED_DATA erl_module {
    IndexSlot slot;		/* Must be located at top of struct! */
    int module;			/* Atom index for module (not tagged). */

    struct erl_module_instance curr;
    struct erl_module_instance old; /* protected by "old_code" rwlock */
} SLAVE_SHARED_DATA Module;

Module* erts_get_module(Eterm mod, ErtsCodeIndex code_ix);
Module* erts_put_module(Eterm mod);

void init_module_table(void);
void module_start_staging(void);
void module_end_staging(int commit);
void module_info(int, void *);

Module *module_code(int, ErtsCodeIndex);
int module_code_size(ErtsCodeIndex);
int module_table_sz(void);

#ifndef ERTS_SLAVE
ERTS_GLB_INLINE void erts_rwlock_old_code(ErtsCodeIndex);
ERTS_GLB_INLINE void erts_rwunlock_old_code(ErtsCodeIndex);
ERTS_GLB_INLINE void erts_rlock_old_code(ErtsCodeIndex);
ERTS_GLB_INLINE void erts_runlock_old_code(ErtsCodeIndex);
#ifdef ERTS_ENABLE_LOCK_CHECK
int erts_is_old_code_rlocked(ErtsCodeIndex);
#endif

#if ERTS_GLB_INLINE_INCL_FUNC_DEF

extern erts_smp_rwmtx_t the_old_code_rwlocks[ERTS_NUM_CODE_IX];

ERTS_GLB_INLINE void erts_rwlock_old_code(ErtsCodeIndex code_ix)
{
    erts_smp_rwmtx_rwlock(&the_old_code_rwlocks[code_ix]);
}
ERTS_GLB_INLINE void erts_rwunlock_old_code(ErtsCodeIndex code_ix)
{
    erts_smp_rwmtx_rwunlock(&the_old_code_rwlocks[code_ix]);
}
ERTS_GLB_INLINE void erts_rlock_old_code(ErtsCodeIndex code_ix)
{
    erts_smp_rwmtx_rlock(&the_old_code_rwlocks[code_ix]);
}
ERTS_GLB_INLINE void erts_runlock_old_code(ErtsCodeIndex code_ix)
{
    erts_smp_rwmtx_runlock(&the_old_code_rwlocks[code_ix]);
}

#ifdef ERTS_ENABLE_LOCK_CHECK
ERTS_GLB_INLINE int erts_is_old_code_rlocked(ErtsCodeIndex code_ix)
{
    return erts_smp_lc_rwmtx_is_rlocked(&the_old_code_rwlocks[code_ix]);
}
#endif

#endif /* ERTS_GLB_INLINE_INCL_FUNC_DEF */

#endif /* !ERTS_SLAVE */

#endif /* !__MODULE_H__ */
