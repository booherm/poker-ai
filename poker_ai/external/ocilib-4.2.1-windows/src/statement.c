/*
 * OCILIB - C Driver for Oracle (C Wrapper for Oracle OCI)
 *
 * Website: http://www.ocilib.net
 *
 * Copyright (c) 2007-2016 Vincent ROGIER <vince.rogier@ocilib.net>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "ocilib_internal.h"

/* ********************************************************************************************* *
 *                             PRIVATE VARIABLES
 * ********************************************************************************************* */

#if OCI_VERSION_COMPILE >= OCI_9_0
static unsigned int TimestampTypeValues[]  = { OCI_TIMESTAMP, OCI_TIMESTAMP_TZ, OCI_TIMESTAMP_LTZ };
static unsigned int IntervalTypeValues[]   = { OCI_INTERVAL_YM, OCI_INTERVAL_DS };
static unsigned int LobTypeValues[]        = { OCI_CLOB, OCI_NCLOB, OCI_BLOB };
#endif

static unsigned int FileTypeValues[]       = { OCI_CFILE, OCI_BFILE };

static unsigned int FetchModeValues[]      = { OCI_SFM_DEFAULT, OCI_SFM_SCROLLABLE };
static unsigned int BindModeValues[]       = { OCI_BIND_BY_POS, OCI_BIND_BY_NAME };
static unsigned int BindAllocationValues[] = { OCI_BAM_EXTERNAL, OCI_BAM_INTERNAL };
static unsigned int LongModeValues[]       = { OCI_LONG_EXPLICIT, OCI_LONG_IMPLICIT };

/* ********************************************************************************************* *
 *                             PRIVATE FUNCTIONS
 * ********************************************************************************************* */

#define SET_ARG_NUM(type, func)                                     \
    type src = func(rs, i), *dst = ( type *) va_arg(args, type *);  \
    if (dst)                                                        \
    {                                                               \
        *dst = src;                                                 \
    }                                                               \

#define SET_ARG_HANDLE(type, func, assign)                          \
    type *src = func(rs, i), *dst = ( type *) va_arg(args, type *); \
    if (src && dst)                                                 \
    {                                                               \
       res = assign(dst, src);                                      \
    }                                                               \

#define OCI_BIND_CALL(stmt, name, data, type, check, func)          \
                                                                    \
    OCI_LIB_CALL_ENTER(boolean, FALSE)                              \
                                                                    \
    OCI_CHECK_BIND_CALL(stmt, name, data, type, check)              \
                                                                    \
    call_retval = call_status = func;                               \
    OCI_LIB_CALL_EXIT()                                             \

#define OCI_REGISTER_CALL(stmt, name, func)                         \
                                                                    \
    OCI_LIB_CALL_ENTER(boolean, FALSE)                              \
                                                                    \
    OCI_CHECK_REGISTER_CALL(stmt, name)                             \
                                                                    \
    call_retval = call_status = func;                               \
    OCI_LIB_CALL_EXIT()                                             \

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindFreeAll
 * --------------------------------------------------------------------------------------------- */

boolean OCI_BindFreeAll
(
    OCI_Statement *stmt
)
{
    int i;

    OCI_CHECK(NULL == stmt, FALSE);

    /* free user binds */

    if (stmt->ubinds)
    {
        for(i = 0; i < stmt->nb_ubinds; i++)
        {
            OCI_BindFree(stmt->ubinds[i]);
        }

        OCI_FREE(stmt->ubinds)
    }

    /* free register binds */

    if (stmt->rbinds)
    {
        for(i = 0; i < stmt->nb_rbinds; i++)
        {
            OCI_BindFree(stmt->rbinds[i]);
        }

        OCI_FREE(stmt->rbinds)
    }

    stmt->nb_ubinds = 0;
    stmt->nb_rbinds = 0;

    return TRUE;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindCheck
 * --------------------------------------------------------------------------------------------- */

boolean OCI_BindCheck
(
    OCI_Statement *stmt
)
{
    boolean res   = TRUE;
    ub4 i, j;

    OCI_CHECK(NULL == stmt, FALSE)
    OCI_CHECK(NULL == stmt->ubinds, TRUE);

    for(i = 0; i < stmt->nb_ubinds; i++)
    {
        OCI_Bind *bnd = stmt->ubinds[i];
        sb2      *ind = (sb2 *) bnd->buffer.inds;

        if (OCI_CDT_CURSOR == bnd->type)
        {
            OCI_Statement *bnd_stmt = (OCI_Statement *) bnd->buffer.data;

            OCI_StatementReset(bnd_stmt);

            bnd_stmt->hstate = OCI_OBJECT_ALLOCATED_BIND_STMT;

            /* allocate statement handle */

            res = OCI_SUCCESSFUL(OCI_HandleAlloc((dvoid *) bnd_stmt->con->env,
                                                 (dvoid **) (void *) &bnd_stmt->stmt,
                                                 (ub4) OCI_HTYPE_STMT,
                                                 (size_t) 0, (dvoid **) NULL));

            res = (res && OCI_SetPrefetchSize(stmt, stmt->prefetch_size));
            res = (res && OCI_SetFetchSize(stmt, stmt->fetch_size));
        }

        if ((bnd->direction & OCI_BDM_IN) ||
            (bnd->alloc && OCI_CDT_DATETIME != bnd->type && OCI_CDT_TEXT != bnd->type && OCI_CDT_NUMERIC != bnd->type))
        {
            /* for strings, re-initialize length array with buffer default size */

            if (OCI_CDT_TEXT == bnd->type)
            {
                for (j=0; j < bnd->buffer.count; j++)
                {
                    *(ub2*)(((ub1 *)bnd->buffer.lens) + (sizeof(ub2) * (size_t) j)) = (ub2) bnd->size;
                }
            }

            /* extra work for internal allocated binds buffers */

            if (!bnd->is_array)
            {
                /* - For big integer (64 bits), we use an OCINumber.

                   - Oracle date/time type is the only non scalar type
                     implemented by oracle through a public structure instead
                     of using a handle. So we need to copy the value
                */

                if ((OCI_CDT_NUMERIC == bnd->type) && (SQLT_VNU == bnd->code))
                {
                    res = OCI_NumberSet(stmt->con,  (OCINumber *) bnd->buffer.data,
                                        (uword) sizeof(big_int), bnd->subtype, bnd->code,
                                        (void *) bnd->input);
                }
                else if (bnd->alloc)
                {
                    if (OCI_CDT_DATETIME == bnd->type)
                    {
                        if (bnd->input)
                        {
                            memcpy((void *) bnd->buffer.data, ((OCI_Date *) bnd->input)->handle, sizeof(OCIDate));
                        }
                    }
                    else if (OCI_CDT_TEXT == bnd->type)
                    {
                        if (OCILib.use_wide_char_conv)
                        {
                            /* need conversion if bind buffer was allocated */

                            OCI_StringUTF32ToUTF16(bnd->input, bnd->buffer.data, (bnd->size / sizeof(dbtext)) - 1);
                        }
                    }
                    else
                    {
                        if (bnd->input)
                        {
                            bnd->buffer.data[0] = ((OCI_Datatype *) bnd->input)->handle;
                        }
                    }
                }

                /* for handles, check anyway the value for null data */

                if ((OCI_CDT_BOOLEAN != bnd->type) &&
                    (OCI_CDT_NUMERIC != bnd->type) &&
                    (OCI_CDT_TEXT    != bnd->type) &&
                    (OCI_CDT_RAW     != bnd->type)  &&
                    (OCI_CDT_OBJECT  != bnd->type))
                {
                    if (ind && *ind != ((sb2) OCI_IND_NULL))
                    {
                        *ind = OCI_IND(bnd->buffer.data);
                    }
                }

                /* update bind object indicator pointer with object indicator */

                if (OCI_CDT_OBJECT == bnd->type && ind)
                {
                   if (*ind != ((sb2) OCI_IND_NULL) && bnd->buffer.data)
                   {
                        OCI_Object *obj = (OCI_Object *)bnd->input;

                        if (obj)
                        {
                            bnd->buffer.obj_inds[0] = obj->tab_ind;
                        }
                   }
                   else
                   {
                       *ind = bnd->buffer.null_inds[0] = OCI_IND_NULL;

                       bnd->buffer.obj_inds[0] = (void* ) &bnd->buffer.null_inds[0];
                   }
                }

                if (!res)
                {
                    break;
                }
            }
            else
            {
                for (j = 0; j < bnd->buffer.count && ind; j++, ind++)
                {

                    /* - For big integer (64 bits), we use an OCINumber.

                       - Oracle date/time type is the only non scalar type
                         implemented by oracle through a public structure instead
                         of using a handle. So we need to copy the value
                    */

                    if ((OCI_CDT_NUMERIC == bnd->type) && (SQLT_VNU == bnd->code))
                    {
                        res = OCI_NumberSet(stmt->con,
                                            (OCINumber *) ((ub1 *) bnd->buffer.data +
                                            (size_t) (j*bnd->size)),
                                            (uword) sizeof(big_int), bnd->subtype, bnd->code,
                                            (void *) (((ub1 *) bnd->input) +
                                            (((size_t)j)*sizeof(big_int))));
                    }
                    else if (bnd->alloc)
                    {
                        if (OCI_CDT_DATETIME == bnd->type)
                        {
                            if (bnd->input[j])
                            {
                                memcpy(((ub1 *) bnd->buffer.data) + (size_t) (j*bnd->size),
                                       ((OCI_Date *) bnd->input[j])->handle, sizeof(OCIDate));
                            }
                        }
                        else if (OCI_CDT_TEXT == bnd->type)
                        {
                            if (OCILib.use_wide_char_conv)
                            {
                                /* need conversion if bind buffer was allocated */

                                int offset1 = (bnd->size/sizeof(dbtext))*sizeof(otext);
                                int offset2 = bnd->size;

                                OCI_StringUTF32ToUTF16( (((ub1 *) bnd->input      ) + (j*offset1)),
                                                        (((ub1 *) bnd->buffer.data) + (j*offset2)),
                                                        (bnd->size / sizeof(dbtext)) - 1);
                            }
                        }
                        else
                        {
                            if (bnd->input[j] && bnd->buffer.data)
                            {
                                bnd->buffer.data[j] = ((OCI_Datatype *) bnd->input[j])->handle;
                            }
                        }
                    }

                    /* for handles, check anyway the value for null data */

                    if ((OCI_CDT_BOOLEAN != bnd->type) &&
                        (OCI_CDT_NUMERIC != bnd->type) && 
                        (OCI_CDT_TEXT    != bnd->type) &&
                        (OCI_CDT_RAW     != bnd->type) &&
                        (OCI_CDT_OBJECT  != bnd->type) && ind)
                    {
                        if (*ind != ((sb2) OCI_IND_NULL))
                        {
                            if (bnd->input[j])
                            {
                                *ind = OCI_IND((((OCI_Datatype *)bnd->input[j])->handle));
                            }
                            else
                            {
                                *ind = OCI_IND_NULL;
                            }
                        }
                    }

                    /* update bind object indicator pointer with object indicator */

                    if (OCI_CDT_OBJECT == bnd->type && ind)
                    {
                        if (*ind != ((sb2) OCI_IND_NULL) && bnd->buffer.data)
                        {
                            OCI_Object *obj = (OCI_Object *) bnd->input[j];

                            if (obj)
                            {
                                bnd->buffer.obj_inds[j] = obj->tab_ind;
                            }
                        }
                        else
                        {
                            *ind = bnd->buffer.null_inds[j] = OCI_IND_NULL;

                            bnd->buffer.obj_inds[j] = (void* ) &bnd->buffer.null_inds[j];
                        }
                    }

                    if (!res)
                    {
                        break;
                    }
                }
            }
        }
    }

    return res;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindReset
 * --------------------------------------------------------------------------------------------- */

boolean OCI_BindReset
(
    OCI_Statement *stmt
)
{
    ub4 i, j;
    boolean res = TRUE;

    OCI_CHECK(NULL == stmt, FALSE)
    OCI_CHECK(NULL == stmt->ubinds, FALSE);

    /* avoid unused param warning from compiler */

    i = j = 0;

    for(i = 0; i < stmt->nb_ubinds; i++)
    {
        OCI_Bind *bnd = stmt->ubinds[i];

        if (OCI_CDT_CURSOR == bnd->type)
        {
            OCI_Statement *bnd_stmt = (OCI_Statement *) bnd->buffer.data;

            bnd_stmt->status = OCI_STMT_PREPARED  | OCI_STMT_PARSED |
                               OCI_STMT_DESCRIBED | OCI_STMT_EXECUTED;

            bnd_stmt->type   = OCI_CST_SELECT;
        }

        if ((bnd->direction & OCI_BDM_OUT) && (bnd->input) && (bnd->buffer.data))
        {
            /* only reset bind indicators if bind was not a PL/SQL bind
               that can have output values
            */

            if (!(OCI_IS_PLSQL_STMT(stmt->type)))
            {
                memset(bnd->buffer.inds, 0, ((size_t) bnd->buffer.count) * sizeof(sb2));
            }
            else
            {
                /* extra work for internal allocated binds buffers with PL/SQL */

                if (!bnd->is_array)
                {
                    /* - For big integer (64 bits), we use an OCINumber.

                       - Oracle date/time type is the only non scalar type
                         implemented by oracle through a public structure instead
                         of using a handle. So we need to copy the value
                    */

                    if ((OCI_CDT_NUMERIC == bnd->type) && (SQLT_VNU == bnd->code))
                    {
                        res = OCI_NumberGet(stmt->con, (OCINumber *) bnd->buffer.data,
                                            (uword) sizeof(big_int), bnd->subtype, bnd->code,
                                            (void *) bnd->input);
                    }
                    else if (bnd->alloc)
                    {

                        if (OCI_CDT_DATETIME == bnd->type)
                        {
                            if (bnd->input)
                            {
                                memcpy(((OCI_Date *) bnd->input)->handle,
                                       (void *) bnd->buffer.data, sizeof(OCIDate));
                            }
                        }
                        else if (OCI_CDT_TEXT == bnd->type)
                        {
                            if (bnd->input && OCILib.use_wide_char_conv)
                            {
                                /* need conversion if bind buffer was allocated */

                                OCI_StringUTF16ToUTF32(bnd->buffer.data, bnd->input, (bnd->size / sizeof(dbtext)) - 1);
                            }
                        }
                        else if (OCI_CDT_OBJECT == bnd->type)
                        {
                            /* update object indicator with bind object indicator pointer */

                            if (bnd->input)
                            {
                                ((OCI_Object *) bnd->input)->tab_ind = (sb2*) bnd->buffer.obj_inds[0];
                            }
                        }
                    }
                }
                else
                {
                    for (j = 0; j < bnd->buffer.count; j++)
                    {

                        /* - For big integer (64 bits), we use an OCINumber.

                           - Oracle date/time type is the only non scalar type
                             implemented by oracle through a public structure instead
                             of using a handle. So we need to copy the value
                        */

                        if ((OCI_CDT_NUMERIC == bnd->type) && (SQLT_VNU == bnd->code))
                        {

                            res = OCI_NumberGet(stmt->con,
                                                (OCINumber *) ((ub1 *) bnd->buffer.data +
                                                (size_t) (j*bnd->size)),
                                                (uword) sizeof(big_int), bnd->subtype, bnd->code,
                                                (void *) (((ub1 *) bnd->input) +
                                                (((size_t)j)*sizeof(big_int))));
                        }
                        else if (bnd->alloc)
                        {
                            if (OCI_CDT_DATETIME == bnd->type)
                            {
                                if (bnd->input[j])
                                {
                                    memcpy(((OCI_Date *) bnd->input[j])->handle,
                                           ((ub1 *) bnd->buffer.data) + (size_t) (j*bnd->size),
                                           sizeof(OCIDate));
                                }
                            }
                            else if (OCI_CDT_TEXT == bnd->type)
                            {
                                if (OCILib.use_wide_char_conv)
                                {
                                    /* need conversion if bind buffer was allocated */

                                    int offset1 = (bnd->size / sizeof(dbtext))*sizeof(otext);
                                    int offset2 = bnd->size;

                                    OCI_StringUTF16ToUTF32((((ub1 *)bnd->buffer.data) + (j*offset2)),
                                        (((ub1 *)bnd->input) + (j*offset1)),
                                        (bnd->size / sizeof(dbtext)) - 1);
                                }
                            }
                            else if (OCI_CDT_OBJECT == bnd->type)
                            {
                                /* update bind object indicator pointer with object indicator */

                                if (bnd->input)
                                {
                                    ((OCI_Object *) bnd->input[j])->tab_ind = (sb2 *) bnd->buffer.obj_inds[j];
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return res;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindData
 * --------------------------------------------------------------------------------------------- */

boolean OCI_BindData
(
    OCI_Statement *stmt,
    void          *data,
    ub4            size,
    const otext   *name,
    ub1            type,
    unsigned int   code,
    unsigned int   mode,
    unsigned int   subtype,
    OCI_TypeInfo  *typinf,
    unsigned int   nbelem
)
{
    boolean res      = TRUE;
    OCI_Bind *bnd    = NULL;
    ub4 exec_mode    = OCI_DEFAULT;
    boolean is_pltbl = FALSE;
    boolean is_array = FALSE;
    boolean reused   = FALSE;
    ub4 *pnbelem     = NULL;
    int index        = 0;
    int prev_index   = -1;
    size_t nballoc   = (size_t) nbelem;

    /* check index if necessary */

    if (OCI_BIND_BY_POS == stmt->bind_mode)
    {
        index = (int) ostrtol(&name[1], NULL, 10);

        if (index <= 0 || index > OCI_BIND_MAX)
        {
            OCI_ExceptionOutOfBounds(stmt->con, index);
            res = FALSE;
        }
    }

    /* check if the bind name has already been used */

    if (res)
    {
        if (OCI_BIND_INPUT == mode)
        {
            prev_index = OCI_BindGetInternalIndex(stmt, name);

            if (prev_index > 0)
            {
                if (!stmt->bind_reuse)
                {
                    OCI_ExceptionBindAlreadyUsed(stmt, name);
                    res = FALSE;
                }
                else
                {
                    bnd = stmt->ubinds[prev_index-1];

                    if (bnd->type != type)
                    {
                        OCI_ExceptionRebindBadDatatype(stmt, name);
                        res = FALSE;
                    }
                    else
                    {
                        reused = TRUE;
                    }
                }

                index = prev_index;
            }
        }
    }

    /* check if we can handle another bind */

    if (res)
    {
        if (OCI_BIND_INPUT == mode)
        {
            if (stmt->nb_ubinds >= OCI_BIND_MAX)
            {
                OCI_ExceptionMaxBind(stmt);
                res = FALSE;
            }

            if (res)
            {
                /* allocate user bind array if necessary */

                if (!stmt->ubinds)
                {
                    stmt->ubinds = (OCI_Bind **) OCI_MemAlloc(OCI_IPC_BIND_ARRAY,
                                                              sizeof(*stmt->ubinds),
                                                              (size_t) OCI_BIND_MAX,
                                                              TRUE);
                }

                res = (NULL != stmt->ubinds);
            }
        }
        else
        {
            if (stmt->nb_rbinds >= OCI_BIND_MAX)
            {
                OCI_ExceptionMaxBind(stmt);
                res = FALSE;
            }

            if (res)
            {
                /* allocate register bind array if necessary */

                if (!stmt->rbinds)
                {
                    stmt->rbinds = (OCI_Bind **) OCI_MemAlloc(OCI_IPC_BIND_ARRAY,
                                                                sizeof(*stmt->rbinds),
                                                                (size_t) OCI_BIND_MAX,
                                                                TRUE);
                }

                res = (NULL != stmt->rbinds);
            }
        }
    }

    /* checks done */

    if (res)
    {
        /* check out the number of elements that the bind variable will hold */

        if (nbelem > 0)
        {
            /* is it a pl/sql table bind ? */

            if (OCI_IS_PLSQL_STMT(stmt->type))
            {
                is_pltbl = TRUE;
                is_array = TRUE;
            }
        }
        else
        {
            nbelem   = stmt->nb_iters;
            is_array = stmt->bind_array;
        }

        /* compute iterations */
        if (nballoc < stmt->nb_iters_init)
        {
            nballoc = (size_t) stmt->nb_iters_init;
        }

        /* create hash table for mapping bind names / index */

        if (!stmt->map)
        {
            stmt->map = OCI_HashCreate(OCI_HASH_DEFAULT_SIZE, OCI_HASH_INTEGER);

            res = (NULL != stmt->map);
        }
    }

    /* allocate bind object */

    if (res)
    {
        if (!bnd)
        {
            bnd = (OCI_Bind *) OCI_MemAlloc(OCI_IPC_BIND, sizeof(*bnd), (size_t) 1, TRUE);
        }

        res = (NULL != bnd);
    }

    /* allocate indicators array */

    if (res)
    {
        if (!bnd->buffer.inds)
        {
            bnd->buffer.inds = (void *) OCI_MemAlloc(OCI_IPC_INDICATOR_ARRAY,
                                                     sizeof(sb2), nballoc, TRUE);
        }

        res = (NULL != bnd->buffer.inds);
    }

    /* allocate object indicators pointer array */

    if (res)
    {
        if (OCI_CDT_OBJECT == type)
        {
            if (!bnd->buffer.obj_inds)
            {
                bnd->buffer.obj_inds = (void **) OCI_MemAlloc(OCI_IPC_INDICATOR_ARRAY,
                                                             sizeof(void *), nballoc, TRUE);

                res = (NULL != bnd->buffer.obj_inds);
            }

            if (!bnd->buffer.null_inds)
            {
                bnd->buffer.null_inds = (sb2 *) OCI_MemAlloc(OCI_IPC_INDICATOR_ARRAY,
                                                             sizeof(sb2 *), nballoc, TRUE);

                res = (NULL != bnd->buffer.null_inds);
            }
        }
    }

    /* check need for PL/SQL table extra info */

    if (res && is_pltbl)
    {
        bnd->nbelem = nbelem;
        pnbelem     = &bnd->nbelem;

        /* allocate array of returned codes */

        if (!bnd->plrcds)
        {
            bnd->plrcds = (ub2 *) OCI_MemAlloc(OCI_IPC_PLS_RCODE_ARRAY,
                                                sizeof(ub2), nballoc, TRUE);
        }

        res = (NULL != bnd->plrcds);
    }

    /* for handle based data types, we need to allocate an array of handles for
       bind calls because OCILIB uses external arrays of OCILIB Objects */

    if (res && (OCI_BIND_INPUT == mode))
    {
        if (OCI_BAM_EXTERNAL == stmt->bind_alloc_mode)
        {
            if ((OCI_CDT_RAW     != type)  &&
                (OCI_CDT_LONG    != type)  &&
                (OCI_CDT_CURSOR  != type)  &&
                (OCI_CDT_LONG    != type)  &&
                (OCI_CDT_BOOLEAN != type)  &&
                (OCI_CDT_NUMERIC != type || SQLT_VNU == code) &&
                (OCI_CDT_TEXT    != type || OCILib.use_wide_char_conv))
            {
                bnd->alloc = TRUE;

                if (reused && bnd->buffer.data && (bnd->size != (sb4) size))
                {
                    OCI_FREE(bnd->buffer.data)
                }

                if (!bnd->buffer.data)
                {
                    bnd->buffer.data = (void **) OCI_MemAlloc(OCI_IPC_BUFF_ARRAY, (size_t) size,
                                                                   (size_t) nballoc, TRUE);
                }

                res = (NULL != bnd->buffer.data);
            }
            else
            {
                bnd->buffer.data = (void **) data;
            }
        }
    }

    /* setup data length array */

    if (res && ((OCI_CDT_RAW == type) || (OCI_CDT_TEXT == type)))
    {
        if (!bnd->buffer.lens)
        {
            bnd->buffer.lens = (void *) OCI_MemAlloc(OCI_IPC_LEN_ARRAY, sizeof(ub2), nballoc, TRUE);
        }

        res = (NULL != bnd->buffer.lens);

        /* initialize length array with buffer default size */

        if (res)
        {
            unsigned int i;

            for (i=0; i < nbelem; i++)
            {
                *(ub2*)(((ub1 *)bnd->buffer.lens) + sizeof(ub2) * (size_t) i) = (ub2) size;
            }
        }
    }

    /* initialize bind object */

    if (res)
    {
        /* initialize bind attributes */

        bnd->stmt      = stmt;
        bnd->input     = (void **) data;
        bnd->type      = type;
        bnd->size      = size;
        bnd->code      = (ub2) code;
        bnd->subtype   = (ub1) subtype;
        bnd->is_array  = is_array;
        bnd->csfrm     = OCI_CSF_NONE;
        bnd->direction = OCI_BDM_IN_OUT;

        if (!bnd->name)
        {
            bnd->name = ostrdup(name);
        }

        /* initialize buffer */

        bnd->buffer.count   = nbelem;
        bnd->buffer.sizelen = sizeof(ub2);

        /* internal allocation if needed */

        if (!data && (OCI_BAM_INTERNAL == stmt->bind_alloc_mode))
        {
            res = OCI_BindAllocData(bnd);
        }

        /* if we bind an OCI_Long or any output bind, we need to change the
           execution mode to provide data at execute time */

        if (OCI_CDT_LONG == bnd->type)
        {
            OCI_Long *lg = (OCI_Long *)  bnd->input;

            lg->maxsize = size;
            exec_mode   = OCI_DATA_AT_EXEC;

            if (OCI_CLONG == bnd->subtype)
            {
                lg->maxsize /= (unsigned int) sizeof(otext);
                lg->maxsize *= (unsigned int) sizeof(dbtext);
            }
        }
        else if (OCI_BIND_OUTPUT == mode)
        {
            exec_mode = OCI_DATA_AT_EXEC;
        }
    }

    /* OCI binding */

    if (res)
    {
        if (OCI_BIND_BY_POS == stmt->bind_mode)
        {
            OCI_CALL1
            (
                res, stmt->con, stmt,

                OCIBindByPos(stmt->stmt, (OCIBind **) &bnd->buffer.handle,
                             stmt->con->err, (ub4) index, (void *) bnd->buffer.data,
                             bnd->size, bnd->code, bnd->buffer.inds, (ub2 *) bnd->buffer.lens,
                             bnd->plrcds, (ub4) (is_pltbl ? nbelem : 0),
                             pnbelem, exec_mode)
            )
        }
        else
        {
            dbtext * dbstr  = NULL;
            int      dbsize = -1;

            dbstr = OCI_StringGetOracleString(bnd->name, &dbsize);

            OCI_CALL1
            (
                res, stmt->con, stmt,

                OCIBindByName(stmt->stmt, (OCIBind **) &bnd->buffer.handle,
                              stmt->con->err, (OraText *) dbstr, (sb4) dbsize,
                              (void *) bnd->buffer.data, bnd->size, bnd->code,
                              bnd->buffer.inds, (ub2 *) bnd->buffer.lens, bnd->plrcds,
                              (ub4) (is_pltbl ? nbelem : 0),
                              pnbelem, exec_mode)
            )

            OCI_StringReleaseOracleString(dbstr);
        }

        if (SQLT_NTY == code || SQLT_REF == code)
        {
            OCI_CALL1
            (
                res, stmt->con, stmt,

                OCIBindObject((OCIBind *) bnd->buffer.handle, stmt->con->err,
                              (OCIType *) typinf->tdo, (void **) bnd->buffer.data,
                              (ub4 *) NULL, (void **) bnd->buffer.obj_inds,
                              (ub4 *) bnd->buffer.inds)
            )
        }

        if (OCI_BIND_OUTPUT == mode)
        {
            /* register output placeholder */

            OCI_CALL1
            (
                res, stmt->con, stmt,

                OCIBindDynamic((OCIBind *) bnd->buffer.handle, stmt->con->err,
                               (dvoid *) bnd, OCI_ProcInBind,
                               (dvoid *) bnd, OCI_ProcOutBind)
            )
        }
    }

    /* set charset form */

    if (res)
    {
        if ((OCI_CDT_LOB == bnd->type) && (OCI_NCLOB == bnd->subtype))
        {
            ub1 csfrm = SQLCS_NCHAR;

            OCI_CALL1
            (
                res, bnd->stmt->con, bnd->stmt,

                OCIAttrSet((dvoid *) bnd->buffer.handle,
                           (ub4    ) OCI_HTYPE_BIND,
                           (dvoid *) &csfrm,
                           (ub4    ) sizeof(csfrm),
                           (ub4    ) OCI_ATTR_CHARSET_FORM,
                           bnd->stmt->con->err)
            )
        }
    }

    /* on success, we :
         - add the bind handle to the bind array
         - add the bind index to the map
    */

    if (res)
    {
        if (OCI_BIND_INPUT == mode)
        {
            if (!reused)
            {
                stmt->ubinds[stmt->nb_ubinds++] = bnd;

                /* for user binds, add a positive index */

                OCI_HashAddInt(stmt->map, name, stmt->nb_ubinds);
            }
        }
        else
        {
            /* for register binds, add a negative index */

            stmt->rbinds[stmt->nb_rbinds++] = bnd;

            index = (int) stmt->nb_rbinds;

            OCI_HashAddInt(stmt->map, name, -index);
        }
    }

    if (!res)
    {
        if (bnd && (prev_index  == -1))
        {
            OCI_BindFree(bnd);
        }
    }

    return res;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindGetInternalIndex
 * --------------------------------------------------------------------------------------------- */

int OCI_BindGetInternalIndex
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    OCI_HashEntry *he = NULL;
    int index         = -1;

    if (stmt->map)
    {
        he = OCI_HashLookup(stmt->map, name, FALSE);

        while (he)
        {
            /* no more entries or key matched => so we got it ! */

            if (!he->next || ostrcasecmp(he->key, name) == 0)
            {
                /* in order to use the same map for user binds and
                   register binds :
                      - user binds are stored as positive values
                      - registers binds are stored as negatives values
                */

                index = he->values->value.num;

                if (index < 0)
                {
                    index = -index;
                }

                break;
            }
        }
    }

    return index;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_FetchIntoUserVariables
 * --------------------------------------------------------------------------------------------- */

boolean OCI_FetchIntoUserVariables
(
    OCI_Statement *stmt,
    va_list        args
)
{
    OCI_Resultset *rs = NULL;
    boolean res       = FALSE;

    /* get resultset */

    rs = OCI_GetResultset(stmt);

    /* fetch data */

    if (rs)
    {
        res = OCI_FetchNext(rs);
    }

    if (res)
    {
        unsigned int i, n;

        /* loop on column list for updating user given placeholders */

        for (i = 1, n = OCI_GetColumnCount(rs); (i <= n) && res; i++)
        {
            OCI_Column *col = OCI_GetColumn(rs, i);

            int type = va_arg(args, int);

            switch (type)
            {
               case OCI_ARG_TEXT:
                {
                    const otext *src;
                    otext *dst;

                    src = OCI_GetString(rs, i);
                    dst = va_arg(args, otext *);

                    if (dst)
                    {
                        dst[0] = 0;
                    }

                    if (dst && src)
                    {
                        ostrcat(dst, src);
                    }

                    break;
                }
                case OCI_ARG_SHORT:
                {
                    SET_ARG_NUM(short, OCI_GetShort);
                    break;
                }
                case OCI_ARG_USHORT:
                {
                    SET_ARG_NUM(unsigned short, OCI_GetUnsignedShort);
                    break;
                }
                case OCI_ARG_INT:
                {
                    SET_ARG_NUM(int, OCI_GetInt);
                    break;
                }
                case OCI_ARG_UINT:
                {
                    SET_ARG_NUM(unsigned int, OCI_GetUnsignedInt);
                    break;
                }
                case OCI_ARG_BIGINT:
                {
                    SET_ARG_NUM(big_int, OCI_GetBigInt);
                    break;
                }
                case OCI_ARG_BIGUINT:
                {
                    SET_ARG_NUM(big_uint, OCI_GetUnsignedBigInt);
                    break;
                }
                case OCI_ARG_DOUBLE:
                {
                    SET_ARG_NUM(double, OCI_GetDouble);
                    break;
                }
                case OCI_ARG_FLOAT:
                {
                    SET_ARG_NUM(float, OCI_GetFloat);
                    break;
                }
                case OCI_ARG_DATETIME:
                {
                    SET_ARG_HANDLE(OCI_Date, OCI_GetDate, OCI_DateAssign);
                    break;
                }
                case OCI_ARG_RAW:
                {
                    OCI_GetRaw(rs, i, va_arg(args, otext *), col->bufsize);
                    break;
                }
                case OCI_ARG_LOB:
                {
                    SET_ARG_HANDLE(OCI_Lob, OCI_GetLob, OCI_LobAssign);
                    break;
                }
                case OCI_ARG_FILE:
                {
                    SET_ARG_HANDLE(OCI_File, OCI_GetFile, OCI_FileAssign);
                    break;
                }
                case OCI_ARG_TIMESTAMP:
                {
                    SET_ARG_HANDLE(OCI_Timestamp, OCI_GetTimestamp, OCI_TimestampAssign);
                    break;
                }
                case OCI_ARG_INTERVAL:
                {
                    SET_ARG_HANDLE(OCI_Interval, OCI_GetInterval, OCI_IntervalAssign);
                    break;
                }
                case OCI_ARG_OBJECT:
                {
                    SET_ARG_HANDLE(OCI_Object, OCI_GetObject, OCI_ObjectAssign);
                    break;
                }
                case OCI_ARG_COLLECTION:
                {
                    SET_ARG_HANDLE(OCI_Coll, OCI_GetColl, OCI_CollAssign);
                    break;
                }
                case OCI_ARG_REF:
                {
                    SET_ARG_HANDLE(OCI_Ref, OCI_GetRef, OCI_RefAssign);
                    break;
                }
                default:
                {
                    OCI_ExceptionMappingArgument(stmt->con, stmt, type);

                    res = FALSE;

                    break;
                }
            }
        }
    }

    return res;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_StatementInit
 * --------------------------------------------------------------------------------------------- */

OCI_Statement * OCI_StatementInit
(
    OCI_Connection *con,
    OCI_Statement **pstmt,
    OCIStmt        *handle,
    boolean         is_desc,
    const otext    *sql
)
{
    OCI_Statement * stmt = NULL;
    boolean res = FALSE;

    OCI_CHECK(NULL == pstmt, NULL);

    if (!*pstmt)
    {
        *pstmt = (OCI_Statement *) OCI_MemAlloc(OCI_IPC_STATEMENT, sizeof(*stmt), (size_t) 1, TRUE);
    }

    if (*pstmt)
    {
        stmt = *pstmt;

        stmt->con  = con;
        stmt->stmt = handle;

        stmt->exec_mode       = OCI_DEFAULT;
        stmt->long_size       = OCI_SIZE_LONG;
        stmt->bind_reuse      = FALSE;
        stmt->bind_mode       = OCI_BIND_BY_NAME;
        stmt->long_mode       = OCI_LONG_EXPLICIT;
        stmt->bind_alloc_mode = OCI_BAM_EXTERNAL;
        stmt->fetch_size      = OCI_FETCH_SIZE;
        stmt->prefetch_size   = OCI_PREFETCH_SIZE;

        res = TRUE;

        /* reset statement */

        OCI_StatementReset(stmt);

        if (is_desc)
        {
            stmt->hstate = OCI_OBJECT_FETCHED_CLEAN;
            stmt->status = OCI_STMT_PREPARED  | OCI_STMT_PARSED |
                           OCI_STMT_DESCRIBED | OCI_STMT_EXECUTED;
            stmt->type   = OCI_CST_SELECT;

            if (sql)
            {
                stmt->sql = ostrdup(sql);
            }
            else
            {
                dbtext *dbstr    = NULL;
                int     dbsize   = 0;

                OCI_CALL1
                (
                    res, con, stmt,

                    OCIAttrGet((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT,
                               (dvoid *)  &dbstr, (ub4 *) &dbsize,
                               (ub4) OCI_ATTR_STATEMENT, stmt->con->err);
                )

                if (res && dbstr)
                {
                    stmt->sql = OCI_StringDuplicateFromOracleString(dbstr, dbcharcount(dbsize));

                    res = (NULL != stmt->sql);
                }
            }

            /* Setting fetch attributes here as the statement is already prepared */

            res = (res && OCI_SetPrefetchSize(stmt, stmt->prefetch_size));
            res = (res && OCI_SetFetchSize(stmt, stmt->fetch_size));
        }
        else
        {
            /* allocate handle for non fetched cursor */

            stmt->hstate = OCI_OBJECT_ALLOCATED;
        }
    }

    /* check for failure */

    if (!res && stmt)
    {
        OCI_StatementFree(stmt);
        *pstmt = stmt = NULL;
    }

    return stmt;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_StatementReset
 * --------------------------------------------------------------------------------------------- */

boolean OCI_StatementReset
(
    OCI_Statement *stmt
)
{
    boolean res  = TRUE;

#if OCI_VERSION_COMPILE >= OCI_9_2

    ub4 mode = OCI_DEFAULT;

    if ((OCILib.version_runtime >= OCI_9_2) && (stmt->nb_rbinds > 0))
    {
        /*  if we had registered binds, we must delete the statement from the cache.
            Because, if we execute another sql with "returning into clause",
            OCI_ProcInBind won't be called by OCI. Nice Oracle bug ! */
        mode = OCI_STRLS_CACHE_DELETE;
    }

#endif

    /* reset batch errors */

    res = OCI_BatchErrorClear(stmt);

    /* free resultsets */

    res = OCI_ReleaseResultsets(stmt);

    /* free in/out binds */

    res = OCI_BindFreeAll(stmt);

    /* free bind map */

    if (stmt->map)
    {
        OCI_HashFree(stmt->map);
    }

    /* free handle if needed */

    if (stmt->stmt)
    {
        if (OCI_OBJECT_ALLOCATED == stmt->hstate)
        {

        #if OCI_VERSION_COMPILE >= OCI_9_2

            if (OCILib.version_runtime >= OCI_9_2)
            {
                OCIStmtRelease(stmt->stmt, stmt->con->err, NULL, 0, mode);
            }
            else

        #endif

            {
                OCI_HandleFree((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT);
            }

            stmt->stmt = NULL;
        }
        else if (OCI_OBJECT_ALLOCATED_BIND_STMT == stmt->hstate)
        {
            OCI_HandleFree((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT);

            stmt->stmt = NULL;
        }
    }

    /* free sql statement */

    OCI_FREE(stmt->sql)

    stmt->rsts          = NULL;
    stmt->stmts         = NULL;
    stmt->sql           = NULL;
    stmt->map           = NULL;
    stmt->batch         = NULL;

    stmt->nb_rs         = 0;
    stmt->nb_stmt       = 0;

    stmt->status        = OCI_STMT_CLOSED;
    stmt->type          = OCI_UNKNOWN;
    stmt->bind_array    = FALSE;

    stmt->nb_iters      = 1;
    stmt->nb_iters_init = 1;
    stmt->dynidx        = 0;
    stmt->err_pos       = 0;

    return res;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_StatementClose
 * --------------------------------------------------------------------------------------------- */

boolean OCI_StatementClose
(
    OCI_Statement *stmt
)
{
    boolean res    = TRUE;
    OCI_Error *err = NULL;

    OCI_CHECK(NULL == stmt, FALSE);

    /* clear statement reference from current error object */

    err = OCI_ErrorGet(FALSE);

    if (err && err->stmt == stmt)
    {
        err->stmt = NULL;
    }

    /* reset data */

    res = OCI_StatementReset(stmt);

    return res;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BatchErrorClear
 * --------------------------------------------------------------------------------------------- */

boolean OCI_BatchErrorClear
(
    OCI_Statement *stmt
)
{
    boolean res = TRUE;

    if (stmt->batch)
    {
        /* free internal array of OCI_Errors */

        OCI_FREE(stmt->batch->errs)

        /* free batch structure */

        OCI_FREE(stmt->batch)
    }

    return res;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_StatementCheckImplicitResultsets
 * --------------------------------------------------------------------------------------------- */

boolean OCI_StatementCheckImplicitResultsets
(
    OCI_Statement *stmt
)
{
    boolean res = TRUE;


#if OCI_VERSION_COMPILE >= OCI_12_1

    if (OCILib.version_runtime >= OCI_12_1)
    {
        OCI_CALL1
        (
            res, stmt->con, stmt,

            OCIAttrGet((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT,
                        (dvoid *) &stmt->nb_stmt, (ub4 *) NULL,
                        (ub4) OCI_ATTR_IMPLICIT_RESULT_COUNT, stmt->con->err)
        )

        if (res && stmt->nb_stmt > 0)
        {
            OCIStmt *result  = NULL;
            ub4      rs_type = OCI_UNKNOWN;
            ub4      i       = 0;

            /* allocate resultset handles array */

            stmt->stmts = (OCI_Statement **) OCI_MemAlloc(OCI_IPC_STATEMENT_ARRAY, sizeof(*stmt->stmts),
                                                          (size_t) stmt->nb_stmt, TRUE);

            if (!stmt->stmts)
            {
                res = FALSE;
            }

            if (res)
            {
                stmt->rsts = (OCI_Resultset **) OCI_MemAlloc(OCI_IPC_RESULTSET_ARRAY, sizeof(*stmt->rsts),
                                                             (size_t) stmt->nb_stmt, TRUE);

                if (!stmt->rsts)
                {
                    res = FALSE;
                }
            }

            while (res && OCI_SUCCESS == OCIStmtGetNextResult(stmt->stmt, stmt->con->err, (dvoid  **) &result,
                                                              &rs_type, OCI_DEFAULT))
            {
                if (OCI_RESULT_TYPE_SELECT == rs_type)
                {
                    stmt->stmts[i] = OCI_StatementInit(stmt->con, &stmt->stmts[i], result, TRUE, NULL);

                    if (stmt->stmts[i])
                    {
                        stmt->rsts[i] = OCI_ResultsetCreate(stmt->stmts[i], stmt->stmts[i]->fetch_size);

                        if (stmt->stmts[i])
                        {
                            i++;
                            stmt->nb_rs++;
                        }
                        else
                        {
                            res = FALSE;
                        }
                    }
                    else
                    {
                        res = FALSE;
                    }
                }
            }
        }
    }

#endif

    return res;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BatchErrorsInit
 * --------------------------------------------------------------------------------------------- */

boolean OCI_BatchErrorInit
(
    OCI_Statement *stmt
)
{
    boolean res   = TRUE;
    ub4 err_count = 0;

    OCI_BatchErrorClear(stmt);

    /* all OCI call here are not checked for errors as we already dealing
       with an array DML error */

    OCIAttrGet((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT,
               (dvoid *) &err_count, (ub4 *) NULL,
               (ub4) OCI_ATTR_NUM_DML_ERRORS, stmt->con->err);

    if (err_count > 0)
    {
        OCIError *hndl = NULL;

        /* allocate batch error structure */

        stmt->batch = (OCI_BatchErrors *) OCI_MemAlloc(OCI_IPC_BATCH_ERRORS,
                                                       sizeof(*stmt->batch),
                                                       (size_t) 1, TRUE);

        res = (NULL != stmt->batch);

        /* allocate array of error objects */

        if (res)
        {
            stmt->batch->errs = (OCI_Error *) OCI_MemAlloc(OCI_IPC_ERROR,
                                                           sizeof(*stmt->batch->errs),
                                                           (size_t) err_count, TRUE);

            res = (NULL != stmt->batch->errs);
        }

        if (res)
        {
            /* allocate OCI error handle */

            res = OCI_SUCCESSFUL(OCI_HandleAlloc((dvoid  *) stmt->con->env,
                                                 (dvoid **) (void *) &hndl,
                                                 (ub4) OCI_HTYPE_ERROR,
                                                 (size_t) 0, (dvoid **) NULL));
        }

        /* loop on the OCI errors to fill OCILIB error objects */

        if (res)
        {
            ub4 i;

            stmt->batch->count = err_count;

            for (i = 0; i < stmt->batch->count; i++)
            {
                int dbsize  = -1;
                dbtext *dbstr = NULL;

                OCI_Error *err = &stmt->batch->errs[i];

                OCIParamGet((dvoid *) stmt->con->err, OCI_HTYPE_ERROR,
                            stmt->con->err, (dvoid **) (void *) &hndl, i);

                /* get row offset */

                OCIAttrGet((dvoid *) hndl, (ub4) OCI_HTYPE_ERROR,
                           (void *) &err->row, (ub4 *) NULL,
                           (ub4) OCI_ATTR_DML_ROW_OFFSET, stmt->con->err);

                /* fill error attributes */

                err->type = OCI_ERR_ORACLE;
                err->con  = stmt->con;
                err->stmt = stmt;

                /* OCILIB indexes start at 1 */

                err->row++;

                /* get error string */

                dbsize = (int) osizeof(err->str) - 1;

                dbstr = OCI_StringGetOracleString(err->str, &dbsize);

                OCIErrorGet((dvoid *) hndl,
                            (ub4) 1,
                            (OraText *) NULL, &err->sqlcode,
                            (OraText *) dbstr,
                            (ub4) dbsize,
                            (ub4) OCI_HTYPE_ERROR);

                OCI_StringCopyOracleStringToNativeString(dbstr, err->str, dbcharcount(dbsize));
                OCI_StringReleaseOracleString(dbstr);
            }
        }

        /* release error handle */

        if (hndl)
        {
            OCI_HandleFree(hndl, OCI_HTYPE_ERROR);
        }
    }

    return res;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_PrepareInternal
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_PrepareInternal
(
    OCI_Statement *stmt,
    const otext   *sql
)
{
    boolean res    = TRUE;
    dbtext *dbstr  = NULL;
    int     dbsize = -1;

    /* reset statement */

    res = OCI_StatementReset(stmt);

    if (res)
    {
        /* store SQL */

        stmt->sql = ostrdup(sql);

        dbstr = OCI_StringGetOracleString(stmt->sql, &dbsize);

        if (OCILib.version_runtime < OCI_9_2)
        {
            /* allocate handle */

            res = OCI_SUCCESSFUL(OCI_HandleAlloc((dvoid *) stmt->con->env,
                                                 (dvoid **) (void *) &stmt->stmt,
                                                 (ub4) OCI_HTYPE_STMT,
                                                 (size_t) 0, (dvoid **) NULL));
        }
    }

    if (res )
    {
        /* prepare SQL */

    #if OCI_VERSION_COMPILE >= OCI_9_2

        if (OCILib.version_runtime >= OCI_9_2)
        {
            OCI_CALL1
            (
                res, stmt->con, stmt,

                OCIStmtPrepare2(stmt->con->cxt, &stmt->stmt, stmt->con->err, (OraText *) dbstr,
                               (ub4) dbsize, NULL, 0, (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT)
            )
        }
        else

    #endif

        {
            OCI_CALL1
            (
                res, stmt->con, stmt,

                OCIStmtPrepare(stmt->stmt,stmt->con->err, (OraText *) dbstr,
                               (ub4) dbsize, (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT)
            )
        }

        /* get statement type */

        OCI_CALL1
        (
            res, stmt->con, stmt,

            OCIAttrGet((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT,
                       (dvoid *) &stmt->type, (ub4 *) NULL,
                       (ub4) OCI_ATTR_STMT_TYPE, stmt->con->err)
        )
    }

    OCI_StringReleaseOracleString(dbstr);

    /* update statement status */

    if (res)
    {
        stmt->status = OCI_STMT_PREPARED;

        res = (res && OCI_SetPrefetchSize(stmt, stmt->prefetch_size));
        res = (res && OCI_SetFetchSize(stmt, stmt->fetch_size));
    }

    return res;
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_ExecuteInternal
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_ExecuteInternal
(
    OCI_Statement *stmt,
    ub4            mode
)
{
    boolean res  = TRUE;
    sword status = OCI_SUCCESS;
    ub4 iters    = 0;

    /* set up iterations and mode values for execution */

    if (OCI_CST_SELECT == stmt->type)
    {
        mode |= stmt->exec_mode;
    }
    else
    {
        iters = stmt->nb_iters;

        /* for array DML, use batch error mode */

        if (iters > 1)
        {
            mode = mode | OCI_BATCH_ERRORS;
        }
    }

    /* reset batch errors */

    OCI_BatchErrorClear(stmt);

    /* check bind objects for updating their null indicator status */

    res = res && OCI_BindCheck(stmt);

    /* check current resultsets */

    if (res && stmt->rsts)
    {
        /* resultsets are freed before any prepare operations.
           So, if we got ones here, it means the same SQL order
           is re-executed */

        if (OCI_CST_SELECT == stmt->type)
        {
            /* just reinitialize the current resultset */

            res = OCI_ResultsetInit(stmt->rsts[0]);
        }
        else
        {
            /* Must free previous resultsets for 'returning into'
               SQL orders that can produce multiple resultsets */

            res = OCI_ReleaseResultsets(stmt);
        }
    }

    /* Oracle execute call */

    if (res)
    {

        status = OCIStmtExecute(stmt->con->cxt, stmt->stmt, stmt->con->err, iters,
                                (ub4)0, (OCISnapshot *)NULL, (OCISnapshot *)NULL, mode);

        /* reset input binds indicators status even if execution failed */

        OCI_BindReset(stmt);
    } 

    /* check result */

    res = ((OCI_SUCCESS == status) || (OCI_SUCCESS_WITH_INFO == status) || (OCI_NEED_DATA == status));

    if (OCI_SUCCESS_WITH_INFO == status)
    {
        OCI_ExceptionOCI(stmt->con->err, stmt->con, stmt, TRUE);
    }

    /* on batch mode, check if any error occurred */

    if (mode & OCI_BATCH_ERRORS)
    {
        /* build batch error list if the statement is array DML */

        OCI_BatchErrorInit(stmt);

        if (stmt->batch)
        {
            res = (stmt->batch->count == 0);
        }
    }

    /* update status on success */

    if (res)
    {
        if (mode & OCI_PARSE_ONLY)
        {
            stmt->status |= OCI_STMT_PARSED;
        }
        else if (mode & OCI_DESCRIBE_ONLY)
        {
            stmt->status |= OCI_STMT_PARSED;
            stmt->status |= OCI_STMT_DESCRIBED;
        }
        else
        {
            stmt->status |= OCI_STMT_PARSED;
            stmt->status |= OCI_STMT_DESCRIBED;
            stmt->status |= OCI_STMT_EXECUTED;

            /* commit if necessary */

            if (stmt->con->autocom)
            {
                OCI_Commit(stmt->con);
            }

            /* check if any implicit results are available */

            res = OCI_StatementCheckImplicitResultsets(stmt);

        }
    }
    else
    {
        /* get parse error position type */

        /* (one of the rare OCI call not enclosed with a OCI_CALLX macro ...) */

        OCIAttrGet((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT,
                   (dvoid *) &stmt->err_pos, (ub4 *) NULL,
                   (ub4) OCI_ATTR_PARSE_ERROR_OFFSET, stmt->con->err);

        /* raise exception */

        OCI_ExceptionOCI(stmt->con->err, stmt->con, stmt, FALSE);
    }

    return res;
}

/* ********************************************************************************************* *
 *                            PUBLIC FUNCTIONS
 * ********************************************************************************************* */

/* --------------------------------------------------------------------------------------------- *
 * OCI_StatementCreate
 * --------------------------------------------------------------------------------------------- */

OCI_Statement * OCI_API OCI_StatementCreate
(
    OCI_Connection *con
)
{
    OCI_Item *item = NULL;

    OCI_LIB_CALL_ENTER(OCI_Statement *, NULL)

    OCI_CHECK_PTR(OCI_IPC_CONNECTION, con)

    /* create statement object */

    item = OCI_ListAppend(con->stmts, sizeof(*call_retval));

    if (item)
    {
        call_retval = OCI_StatementInit(con, (OCI_Statement **) &item->data, NULL, FALSE, NULL);
        call_status = (NULL != call_retval);
    }

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_StatementFree
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_StatementFree
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_OBJECT_FETCHED(stmt)

    OCI_StatementClose(stmt);

    OCI_ListRemove(stmt->con->stmts, stmt);

    OCI_FREE(stmt)

    call_retval = call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_ReleaseResultsets
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_ReleaseResultsets
(
    OCI_Statement *stmt
)
{
    ub4 i;

    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = call_status = TRUE;

    /* Release statements for implicit resultsets */
    if (stmt->stmts)
    {
        for (i = 0; i  < stmt->nb_stmt; i++)
        {
            if (stmt->rsts[i])
            {
                if (!OCI_StatementClose(stmt->stmts[i]))
                {
                    call_retval = FALSE;
                }
            }
        }

        OCI_FREE(stmt->rsts)
    }

    /* release resultsets */
    if (stmt->rsts)
    {
        for (i = 0; i  < stmt->nb_rs; i++)
        {
            if (stmt->rsts[i])
            {
                if (!OCI_ResultsetFree(stmt->rsts[i]))
                {
                    call_retval = FALSE;
                }
            }
        }

        OCI_FREE(stmt->rsts)
    }

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_Prepare
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_Prepare
(
    OCI_Statement *stmt,
    const otext   *sql
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_PTR(OCI_IPC_STRING, sql)

    call_retval = call_status = OCI_PrepareInternal(stmt, sql);

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_Execute
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_Execute
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = call_status = OCI_ExecuteInternal(stmt, OCI_DEFAULT);

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_ExecuteStmt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_ExecuteStmt
(
    OCI_Statement *stmt,
    const otext   *sql
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = call_status = OCI_PrepareInternal(stmt, sql) && OCI_ExecuteInternal(stmt, OCI_DEFAULT);

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_Parse
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_Parse
(
    OCI_Statement *stmt,
    const otext   *sql
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = call_status = OCI_PrepareInternal(stmt, sql) && OCI_ExecuteInternal(stmt, OCI_PARSE_ONLY);

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_Describe
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_Describe
(
    OCI_Statement *stmt,
    const otext   *sql
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = call_status = OCI_PrepareInternal(stmt, sql);

    if (call_status && OCI_CST_SELECT == stmt->type)
    {
        call_status = OCI_ExecuteInternal(stmt, OCI_DESCRIBE_ONLY);
    }

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_PrepareFmt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_PrepareFmt
(
    OCI_Statement *stmt,
    const otext   *sql,
    ...
)
{
    va_list args;
    int     size;

    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_PTR(OCI_IPC_STRING, sql)

    /* first, get buffer size */

    va_start(args, sql);

    size = OCI_ParseSqlFmt(stmt, NULL, sql, &args);

    va_end(args);

    if (size > 0)
    {
        /* allocate buffer */

        otext *sql_fmt = (otext *) OCI_MemAlloc(OCI_IPC_STRING, sizeof(otext), (size_t) (size+1), TRUE);

        if (sql_fmt)
        {
            /* format buffer */

            va_start(args, sql);

            if (OCI_ParseSqlFmt(stmt, sql_fmt, sql, &args) > 0)
            {
                /* parse buffer */

                call_status = OCI_PrepareInternal(stmt, sql_fmt);
            }

            va_end(args);

            OCI_FREE(sql_fmt)
        }
    }

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_ExecuteStmtFmt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_ExecuteStmtFmt
(
    OCI_Statement *stmt,
    const otext   *sql,
    ...
)
{
    va_list args;
    int     size;

    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_PTR(OCI_IPC_STRING, sql)

    /* first, get buffer size */

    va_start(args, sql);

    size = OCI_ParseSqlFmt(stmt, NULL, sql, &args);

    va_end(args);

    if (size > 0)
    {
        /* allocate buffer */

        otext *sql_fmt = (otext *) OCI_MemAlloc(OCI_IPC_STRING, sizeof(otext), (size_t) (size+1), TRUE);

        if (sql_fmt)
        {
            /* format buffer */

            va_start(args, sql);

            if (OCI_ParseSqlFmt(stmt, sql_fmt, sql, &args) > 0)
            {
                /* prepare and execute SQL buffer */

                call_status = (OCI_PrepareInternal(stmt, sql_fmt) && OCI_ExecuteInternal(stmt, OCI_DEFAULT));
            }

            va_end(args);

            OCI_FREE(sql_fmt)
        }
    }

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_ParseFmt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_ParseFmt
(
    OCI_Statement *stmt,
    const otext   *sql,
    ...
)
{
    va_list args;
    int     size;

    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_PTR(OCI_IPC_STRING, sql)

    /* first, get buffer size */

    va_start(args, sql);

    size = OCI_ParseSqlFmt(stmt, NULL, sql, &args);

    va_end(args);

    if (size > 0)
    {
        /* allocate buffer */

        otext  *sql_fmt = (otext *) OCI_MemAlloc(OCI_IPC_STRING, sizeof(otext), (size_t) (size+1), TRUE);

        if (sql_fmt)
        {
            /* format buffer */

            va_start(args, sql);

            if (OCI_ParseSqlFmt(stmt, sql_fmt, sql, &args) > 0)
            {
                /* prepare and execute SQL buffer */

                call_status = (OCI_PrepareInternal(stmt, sql_fmt) && OCI_ExecuteInternal(stmt, OCI_PARSE_ONLY));
            }

            va_end(args);

            OCI_FREE(sql_fmt)
        }
    }

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_DescribeFmt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_DescribeFmt
(
    OCI_Statement *stmt,
    const otext   *sql,
    ...
)
{
    va_list args;
    int     size;

    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_PTR(OCI_IPC_STRING, sql)

    /* first, get buffer size */

    va_start(args, sql);

    size = OCI_ParseSqlFmt(stmt, NULL, sql, &args);

    va_end(args);

    if (size > 0)
    {
        /* allocate buffer */

        otext  *sql_fmt = (otext *) OCI_MemAlloc(OCI_IPC_STRING, sizeof(otext), (size_t) (size+1), TRUE);

        if (sql_fmt )
        {
            /* format buffer */

            va_start(args, sql);

            if (OCI_ParseSqlFmt(stmt, sql_fmt, sql, &args) > 0)
            {
                /* prepare and execute SQL buffer */

                call_status = (OCI_PrepareInternal(stmt, sql_fmt) && OCI_ExecuteInternal(stmt, OCI_DESCRIBE_ONLY));
            }

            va_end(args);

            OCI_FREE(sql_fmt)
        }
    }

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArraySetSize
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArraySetSize
(
    OCI_Statement *stmt,
    unsigned int   size
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_MIN(stmt->con, stmt, size, 1)
    OCI_CHECK_STMT_STATUS(stmt, OCI_STMT_PREPARED)

    /* if the statements already has binds, we need to check if the new size is
       not greater than the initial size
    */

    if ((stmt->nb_ubinds > 0) && (stmt->nb_iters_init < size))
    {
        OCI_ExceptionBindArraySize(stmt, stmt->nb_iters_init, stmt->nb_iters, size);
    }
    else
    {
        stmt->nb_iters   = size;
        stmt->bind_array = TRUE;

        if (stmt->nb_ubinds == 0)
        {
            stmt->nb_iters_init = stmt->nb_iters;
        }

        call_status = TRUE;
    }

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayGetSize
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_BindArrayGetSize
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, 0)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->nb_iters;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_AllowRebinding
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_AllowRebinding
(
    OCI_Statement *stmt,
    boolean        value
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    stmt->bind_reuse = value;

    call_retval = call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_IsRebindingAllowed
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_IsRebindingAllowed
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->bind_reuse;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
* OCI_BindBoolean
* --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindBoolean
(
    OCI_Statement *stmt,
    const otext   *name,
    boolean       *data
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_BOOLEAN, TRUE)
    OCI_CHECK_EXTENDED_PLSQLTYPES_ENABLED(stmt->con)

#if OCI_VERSION_COMPILE >= OCI_12_1

    call_status = OCI_BindData(stmt, data, sizeof(boolean), name, OCI_CDT_BOOLEAN,
                               SQLT_BOL, OCI_BIND_INPUT, 0, NULL, 0);

#else

    OCI_NOT_USED(name)
    OCI_NOT_USED(data)

#endif

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindShort
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindShort
(
    OCI_Statement *stmt,
    const otext   *name,
    short         *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_SHORT, FALSE,

        OCI_BindData(stmt, data, sizeof(short), name, OCI_CDT_NUMERIC,
                     SQLT_INT, OCI_BIND_INPUT, OCI_NUM_SHORT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfShorts
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfShorts
(
    OCI_Statement *stmt,
    const otext   *name,
    short         *data,
    unsigned int   nbelem
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_SHORT, FALSE,

        OCI_BindData(stmt, data, sizeof(short), name, OCI_CDT_NUMERIC,
                     SQLT_INT, OCI_BIND_INPUT, OCI_NUM_SHORT, NULL, nbelem)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindUnsignedShort
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindUnsignedShort
(
    OCI_Statement  *stmt,
    const otext    *name,
    unsigned short *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_SHORT, FALSE,

        OCI_BindData(stmt, data, sizeof(unsigned short), name, OCI_CDT_NUMERIC,
                     SQLT_UIN, OCI_BIND_INPUT, OCI_NUM_USHORT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfUnsignedShorts
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfUnsignedShorts
(
    OCI_Statement  *stmt,
    const otext    *name,
    unsigned short *data,
    unsigned int    nbelem
)
{
    OCI_BIND_CALL
    (
        stmt, name, data,  OCI_IPC_SHORT, FALSE,

        OCI_BindData(stmt, data, sizeof(unsigned short), name, OCI_CDT_NUMERIC,
                     SQLT_UIN, OCI_BIND_INPUT, OCI_NUM_USHORT, NULL, nbelem)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindInt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindInt
(
    OCI_Statement *stmt,
    const otext   *name,
    int           *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_INT, FALSE,

        OCI_BindData(stmt, data, sizeof(int), name, OCI_CDT_NUMERIC,
                     SQLT_INT, OCI_BIND_INPUT, OCI_NUM_INT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfInts
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfInts
(
    OCI_Statement *stmt,
    const otext   *name,
    int           *data,
    unsigned int   nbelem
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_INT, FALSE,

        OCI_BindData(stmt, data, sizeof(int), name, OCI_CDT_NUMERIC,
                     SQLT_INT, OCI_BIND_INPUT, OCI_NUM_INT, NULL, nbelem)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindUnsignedInt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindUnsignedInt
(
    OCI_Statement *stmt,
    const otext   *name,
    unsigned int  *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_INT, FALSE,

        OCI_BindData(stmt, data, sizeof(unsigned int), name, OCI_CDT_NUMERIC,
                     SQLT_UIN, OCI_BIND_INPUT, OCI_NUM_UINT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfUnsignedInts
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfUnsignedInts
(
    OCI_Statement *stmt,
    const otext   *name,
    unsigned int  *data,
    unsigned int   nbelem
)
{
    OCI_BIND_CALL
    (
        stmt, name, data,  OCI_IPC_INT, FALSE,

        OCI_BindData(stmt, data, sizeof(unsigned int), name, OCI_CDT_NUMERIC,
                     SQLT_UIN, OCI_BIND_INPUT, OCI_NUM_UINT, NULL, nbelem)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindBigInt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindBigInt
(
    OCI_Statement *stmt,
    const otext   *name,
    big_int       *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_BIGINT, FALSE,

        OCI_BindData(stmt, data, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                     SQLT_VNU, OCI_BIND_INPUT, OCI_NUM_BIGINT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfBigInts
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfBigInts
(
    OCI_Statement *stmt,
    const otext   *name,
    big_int       *data,
    unsigned int   nbelem
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_BIGINT, FALSE,

        OCI_BindData(stmt, data, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                     SQLT_VNU, OCI_BIND_INPUT, OCI_NUM_BIGINT, NULL, nbelem)
     )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindUnsignedBigInt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindUnsignedBigInt
(
    OCI_Statement *stmt,
    const otext   *name,
    big_uint      *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_BIGINT, FALSE,

        OCI_BindData(stmt, data, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                     SQLT_VNU, OCI_BIND_INPUT, OCI_NUM_BIGUINT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfUnsignedInts
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfUnsignedBigInts
(
    OCI_Statement *stmt,
    const otext   *name,
    big_uint      *data,
    unsigned int   nbelem
)
{
    OCI_BIND_CALL
    (
        stmt, name, data,  OCI_IPC_BIGINT, FALSE,

        OCI_BindData(stmt, data, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                      SQLT_VNU, OCI_BIND_INPUT, OCI_NUM_BIGUINT, NULL, nbelem)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindString
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindString
(
    OCI_Statement *stmt,
    const otext   *name,
    otext         *data,
    unsigned int   len
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_STRING, FALSE)

    call_status = TRUE;

    if ((len == 0) || len == (UINT_MAX))
    {
        if (data)
        {
            /* only compute length for external bind if no valid length has been provided */

            len = (unsigned int) ostrlen(data);
        }
        else
        {
            /* if data is NULL, it means that binding mode is OCI_BAM_INTERNAL.
               An invalid length passed to the function, we do not have a valid length to
               allocate internal array, thus we need to raise an exception */

            OCI_ExceptionMinimumValue(stmt->con, stmt, 1);

            call_status = FALSE;
        }
    }

    if (call_status)
    {
        call_status = OCI_BindData(stmt, data, (len + 1) * (ub4) sizeof(dbtext), name,
                                    OCI_CDT_TEXT, SQLT_STR, OCI_BIND_INPUT, 0, NULL, 0);
    }

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfStrings
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfStrings
(
    OCI_Statement *stmt,
    const otext   *name,
    otext         *data,
    unsigned int   len,
    unsigned int   nbelem
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_STRING, FALSE)
    OCI_CHECK_MIN(stmt->con, stmt, len, 1)

    call_status = OCI_BindData(stmt, data, (len + 1) * (ub4) sizeof(dbtext), name,
                               OCI_CDT_TEXT, SQLT_STR, OCI_BIND_INPUT, 0, NULL, nbelem);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindRaw
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindRaw
(
    OCI_Statement *stmt,
    const otext   *name,
    void          *data,
    unsigned int   len
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_VOID, FALSE)
    OCI_CHECK_MIN(stmt->con, stmt, len, 1)

    call_status =  OCI_BindData(stmt, data, len, name, OCI_CDT_RAW,
                                SQLT_BIN, OCI_BIND_INPUT, 0, NULL, 0);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfRaws
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfRaws
(
    OCI_Statement *stmt,
    const otext   *name,
    void          *data,
    unsigned int   len,
    unsigned int   nbelem
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_VOID, FALSE)
    OCI_CHECK_MIN(stmt->con, stmt, len, 1)

    call_status =  OCI_BindData(stmt, data, len, name, OCI_CDT_RAW,
                                SQLT_BIN, OCI_BIND_INPUT, 0, NULL, nbelem);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindDouble
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindDouble
(
    OCI_Statement *stmt,
    const otext   *name,
    double        *data
)
{
    unsigned int code = SQLT_FLT;

    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_DOUBLE, FALSE)

#if OCI_VERSION_COMPILE >= OCI_10_1

    if ((OCILib.version_runtime >= OCI_10_1) && (stmt->con->ver_num >= OCI_10_1))
    {
        code = SQLT_BDOUBLE;
    }

#endif

    call_status =  OCI_BindData(stmt, data, sizeof(double), name, OCI_CDT_NUMERIC,
                                code, OCI_BIND_INPUT, OCI_NUM_DOUBLE, NULL, 0);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfDoubles
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfDoubles
(
    OCI_Statement *stmt,
    const otext   *name,
    double        *data,
    unsigned int   nbelem
)
{
    unsigned int code = SQLT_FLT;

    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_DOUBLE, FALSE)

#if OCI_VERSION_COMPILE >= OCI_10_1

    if ((OCILib.version_runtime >= OCI_10_1) && (stmt->con->ver_num >= OCI_10_1))
    {
        code = SQLT_BDOUBLE;
    }

#endif

    call_status = OCI_BindData(stmt, data, sizeof(double), name, OCI_CDT_NUMERIC,
                               code, OCI_BIND_INPUT, OCI_NUM_DOUBLE, NULL, nbelem);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindFloat
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindFloat
(
    OCI_Statement *stmt,
    const otext   *name,
    float         *data
)
{
    unsigned int code = SQLT_FLT;

    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_FLOAT, FALSE);

#if OCI_VERSION_COMPILE >= OCI_10_1

    if ((OCILib.version_runtime >= OCI_10_1) && (stmt->con->ver_num >= OCI_10_1))
    {
        code = SQLT_BFLOAT;
    }

#endif

    call_status =  OCI_BindData(stmt, data, sizeof(float), name, OCI_CDT_NUMERIC,
                                code, OCI_BIND_INPUT, OCI_NUM_FLOAT, NULL, 0);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfFloats
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfFloats
(
    OCI_Statement *stmt,
    const otext   *name,
    float         *data,
    unsigned int   nbelem
)
{
    unsigned int code = SQLT_FLT;

    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_FLOAT, FALSE)

#if OCI_VERSION_COMPILE >= OCI_10_1

    if ((OCILib.version_runtime >= OCI_10_1) && (stmt->con->ver_num >= OCI_10_1))
    {
        code = SQLT_BFLOAT;
    }

#endif

    call_status = OCI_BindData(stmt, data, sizeof(float), name, OCI_CDT_NUMERIC,
                               code, OCI_BIND_INPUT, OCI_NUM_FLOAT, NULL, nbelem);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindDate
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindDate
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Date      *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data,  OCI_IPC_DATE, FALSE,

        OCI_BindData(stmt, data, sizeof(OCIDate), name, OCI_CDT_DATETIME,
                     SQLT_ODT, OCI_BIND_INPUT, 0, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfDates
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfDates
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Date     **data,
    unsigned int   nbelem
)
{
    OCI_BIND_CALL
    (
        stmt, name, data,  OCI_IPC_DATE, FALSE,

        OCI_BindData(stmt, data, sizeof(OCIDate), name, OCI_CDT_DATETIME,
                     SQLT_ODT, OCI_BIND_INPUT, 0, NULL, nbelem)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindTimestamp
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindTimestamp
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Timestamp *data
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_TIMESTAMP, TRUE)
    OCI_CHECK_TIMESTAMP_ENABLED(stmt->con)

#if OCI_VERSION_COMPILE >= OCI_9_0

    call_status = OCI_BindData(stmt, data, sizeof(OCIDateTime *), name, OCI_CDT_TIMESTAMP,
                               OCI_ExternalSubTypeToSQLType(OCI_CDT_TIMESTAMP, data->type),
                               OCI_BIND_INPUT, data->type, NULL, 0);

#endif

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfTimestamps
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfTimestamps
(
    OCI_Statement  *stmt,
    const otext    *name,
    OCI_Timestamp **data,
    unsigned int    type,
    unsigned int    nbelem
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_TIMESTAMP, FALSE)
    OCI_CHECK_TIMESTAMP_ENABLED(stmt->con)

#if OCI_VERSION_COMPILE >= OCI_9_0

    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, type, TimestampTypeValues, OTEXT("Timestamp type"))

    call_status = OCI_BindData(stmt, data, sizeof(OCIDateTime *), name, OCI_CDT_TIMESTAMP,
                               OCI_ExternalSubTypeToSQLType(OCI_CDT_TIMESTAMP, type),
                               OCI_BIND_INPUT, type, NULL, nbelem);

#else

    OCI_NOT_USED(name)
    OCI_NOT_USED(type)
    OCI_NOT_USED(nbelem)

#endif

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindInterval
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindInterval
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Interval  *data
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_INTERVAL, TRUE)
    OCI_CHECK_INTERVAL_ENABLED(stmt->con)

#if OCI_VERSION_COMPILE >= OCI_9_0

    call_status = OCI_BindData(stmt, data, sizeof(OCIInterval *), name, OCI_CDT_INTERVAL,
                               OCI_ExternalSubTypeToSQLType(OCI_CDT_INTERVAL, data->type),
                               OCI_BIND_INPUT, data->type, NULL, 0);

#else

    OCI_NOT_USED(name)

#endif

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfIntervals
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfIntervals
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Interval **data,
    unsigned int   type,
    unsigned int   nbelem
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_INTERVAL, FALSE)
    OCI_CHECK_INTERVAL_ENABLED(stmt->con)

#if OCI_VERSION_COMPILE >= OCI_9_0

    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, type, IntervalTypeValues, OTEXT("Interval type"))

    call_retval = OCI_BindData(stmt, data, sizeof(OCIInterval *), name, OCI_CDT_INTERVAL,
                               OCI_ExternalSubTypeToSQLType(OCI_CDT_INTERVAL, type),
                               OCI_BIND_INPUT, type, NULL, nbelem);

#else

    OCI_NOT_USED(name)
    OCI_NOT_USED(type)
    OCI_NOT_USED(nbelem)

#endif

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindObject
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindObject
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Object    *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_OBJECT, TRUE,

        OCI_BindData(stmt, data, sizeof(void *), name, OCI_CDT_OBJECT,
                     SQLT_NTY, OCI_BIND_INPUT, 0, data->typinf, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfObjects
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfObjects
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Object   **data,
    OCI_TypeInfo  *typinf,
    unsigned int   nbelem
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_OBJECT, FALSE)
    OCI_CHECK_PTR(OCI_IPC_TYPE_INFO, typinf)

    call_status = OCI_BindData(stmt, data, sizeof(void *), name, OCI_CDT_OBJECT,
                               SQLT_NTY, OCI_BIND_INPUT, 0, typinf, nbelem);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindLob
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindLob
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Lob       *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_LOB, TRUE,

        OCI_BindData(stmt, data, sizeof(OCILobLocator*), name, OCI_CDT_LOB,
                     OCI_ExternalSubTypeToSQLType(OCI_CDT_LOB, data->type),
                     OCI_BIND_INPUT, data->type, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfLobs
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfLobs
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Lob      **data,
    unsigned int   type,
    unsigned int   nbelem
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_LOB, FALSE)

#if OCI_VERSION_COMPILE >= OCI_9_0
    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, type, LobTypeValues, OTEXT("Lob type"))
#endif 

    call_status = OCI_BindData(stmt, data, sizeof(OCILobLocator*), name, OCI_CDT_LOB,
                               OCI_ExternalSubTypeToSQLType(OCI_CDT_LOB, type),
                               OCI_BIND_INPUT, type, NULL, nbelem);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindFile
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindFile
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_File      *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_FILE, TRUE,

        OCI_BindData(stmt, data, sizeof(OCILobLocator*), name, OCI_CDT_FILE,
                     OCI_ExternalSubTypeToSQLType(OCI_CDT_FILE, data->type),
                     OCI_BIND_INPUT, data->type, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfFiles
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfFiles
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_File     **data,
    unsigned int   type,
    unsigned int   nbelem
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_BIND_CALL(stmt, name, data, OCI_IPC_LOB, OCI_IPC_FILE)
    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, type, FileTypeValues, OTEXT("File type"))

    call_status = OCI_BindData(stmt, data, sizeof(OCILobLocator*), name, OCI_CDT_FILE,
                               OCI_ExternalSubTypeToSQLType(OCI_CDT_FILE, type),
                               OCI_BIND_INPUT, type, NULL, nbelem);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindRef
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindRef
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Ref       *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_REF, TRUE,

        OCI_BindData(stmt, data, sizeof(OCIRef *), name, OCI_CDT_REF,
                     SQLT_REF, OCI_BIND_INPUT, 0, data->typinf, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfRefs
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfRefs
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Ref      **data,
    OCI_TypeInfo  *typinf,
    unsigned int   nbelem
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_REF, TRUE,

        OCI_BindData(stmt, data, sizeof(OCIRef *), name, OCI_CDT_REF,
                     SQLT_REF, OCI_BIND_INPUT, 0, typinf, nbelem)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindColl
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindColl
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Coll      *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_COLLECTION, TRUE,

        OCI_BindData(stmt, data, sizeof(OCIColl*), name, OCI_CDT_COLLECTION, SQLT_NTY,
                     OCI_BIND_INPUT, 0, data->typinf, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindArrayOfColls
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindArrayOfColls
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Coll     **data,
    OCI_TypeInfo  *typinf,
    unsigned int   nbelem
)
{
    OCI_BIND_CALL
    (
        stmt, name, data, OCI_IPC_COLLECTION, TRUE,

        OCI_BindData(stmt, data, sizeof(OCIColl*), name, OCI_CDT_COLLECTION, SQLT_NTY,
                     OCI_BIND_INPUT, 0, typinf, nbelem)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindStatement
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindStatement
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Statement *data
)
{
    OCI_BIND_CALL
    (
        stmt, name, data,  OCI_IPC_STATEMENT, TRUE,

        OCI_BindData(stmt, &data->stmt, sizeof(OCIStmt*), name, OCI_CDT_CURSOR,
                     SQLT_RSET, OCI_BIND_INPUT, 0, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_BindLong
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_BindLong
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_Long      *data,
    unsigned int   size
)
{
    OCI_BIND_CALL
    (
        stmt, name, data,  OCI_IPC_LONG, TRUE,

        OCI_BindData(stmt, data, size, name, OCI_CDT_LONG,
                     OCI_ExternalSubTypeToSQLType(OCI_CDT_LONG, data->type),
                     OCI_BIND_INPUT, data->type, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterShort
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterShort
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    OCI_REGISTER_CALL
    (
        stmt, name,

        OCI_BindData(stmt, NULL, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                     SQLT_VNU, OCI_BIND_OUTPUT, OCI_NUM_SHORT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterUnsignedShort
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterUnsignedShort
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    OCI_REGISTER_CALL
    (
        stmt, name,

        OCI_BindData(stmt, NULL, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                        SQLT_VNU, OCI_BIND_OUTPUT, OCI_NUM_USHORT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterInt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterInt
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    OCI_REGISTER_CALL
    (
        stmt, name,

        OCI_BindData(stmt, NULL, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                     SQLT_VNU, OCI_BIND_OUTPUT, OCI_NUM_INT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterUnsignedInt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterUnsignedInt
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    OCI_REGISTER_CALL
    (
        stmt, name,

        OCI_BindData(stmt, NULL, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                     SQLT_VNU, OCI_BIND_OUTPUT, OCI_NUM_UINT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterBigInt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterBigInt
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    OCI_REGISTER_CALL
    (
        stmt, name,

        OCI_BindData(stmt, NULL, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                     SQLT_VNU, OCI_BIND_OUTPUT, OCI_NUM_BIGINT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterUnsignedBigInt
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterUnsignedBigInt
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    OCI_REGISTER_CALL
    (
        stmt, name,

        OCI_BindData(stmt, NULL, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                     SQLT_VNU, OCI_BIND_OUTPUT, OCI_NUM_BIGUINT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterString
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterString
(
    OCI_Statement *stmt,
    const otext   *name,
    unsigned int   len
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_REGISTER_CALL(stmt, name)
    OCI_CHECK_MIN(stmt->con, stmt, len, 1)

    call_status =  OCI_BindData(stmt, NULL, (len + 1) * (ub4) sizeof(dbtext), name,
                                OCI_CDT_TEXT, SQLT_STR, OCI_BIND_OUTPUT, 0, NULL, 0);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterRaw
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterRaw
(
    OCI_Statement *stmt,
    const otext   *name,
    unsigned int   len
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_REGISTER_CALL(stmt, name)
    OCI_CHECK_MIN(stmt->con, stmt, len, 1)

    call_status = OCI_BindData(stmt, NULL, len, name, OCI_CDT_RAW,
                               SQLT_BIN, OCI_BIND_OUTPUT, 0, NULL, 0);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterDouble
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterDouble
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    OCI_REGISTER_CALL
    (
        stmt, name,

        OCI_BindData(stmt, NULL, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                     SQLT_VNU, OCI_BIND_OUTPUT, OCI_NUM_DOUBLE, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterFloat
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterFloat
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    OCI_REGISTER_CALL
    (
        stmt, name,

        OCI_BindData(stmt, NULL, sizeof(OCINumber), name, OCI_CDT_NUMERIC,
                     SQLT_VNU, OCI_BIND_OUTPUT, OCI_NUM_FLOAT, NULL, 0)
    )
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterDate
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterDate
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    unsigned int code = SQLT_ODT;
    unsigned int size = sizeof(OCIDate);

    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_REGISTER_CALL(stmt, name)

    /* versions of OCI (< 10.2) crashes if SQLT_ODT is passed for output
       data with returning clause.
       It's an Oracle known bug #3269146 */

    if (OCI_GetVersionConnection(stmt->con) < OCI_10_2)
    {
        code = SQLT_DAT;
        size = 7;
    }

    call_status = OCI_BindData(stmt, NULL, size, name, OCI_CDT_DATETIME,
                               code, OCI_BIND_OUTPUT, 0, NULL, 0);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterTimestamp
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterTimestamp
(
    OCI_Statement *stmt,
    const otext   *name,
    unsigned int   type
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_REGISTER_CALL(stmt, name)
    OCI_CHECK_TIMESTAMP_ENABLED(stmt->con)

#if OCI_VERSION_COMPILE >= OCI_9_0

    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, type, TimestampTypeValues, OTEXT("Timestamp type"))

    call_status = OCI_BindData(stmt, NULL, sizeof(OCIDateTime *), name, OCI_CDT_TIMESTAMP,
                               OCI_ExternalSubTypeToSQLType(OCI_CDT_TIMESTAMP, type),
                               OCI_BIND_OUTPUT, type, NULL, 0);

#endif

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterInterval
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterInterval
(
    OCI_Statement *stmt,
    const otext   *name,
    unsigned int   type
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_REGISTER_CALL(stmt, name)
    OCI_CHECK_INTERVAL_ENABLED(stmt->con)

#if OCI_VERSION_COMPILE >= OCI_9_0

    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, type, IntervalTypeValues, OTEXT("Interval type"))

    call_status = OCI_BindData(stmt, NULL, sizeof(OCIInterval *), name, OCI_CDT_INTERVAL,
                               OCI_ExternalSubTypeToSQLType(OCI_CDT_INTERVAL, type),
                               OCI_BIND_OUTPUT, type, NULL, 0);

#endif

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterObject
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterObject
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_TypeInfo  *typinf
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_REGISTER_CALL(stmt, name)
    OCI_CHECK_PTR(OCI_IPC_TYPE_INFO, typinf)

    call_status = OCI_BindData(stmt, NULL, sizeof(void *), name, OCI_CDT_OBJECT,
                               SQLT_NTY, OCI_BIND_OUTPUT, 0, typinf, 0);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterLob
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterLob
(
    OCI_Statement *stmt,
    const otext   *name,
    unsigned int   type
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_REGISTER_CALL(stmt, name)

#if OCI_VERSION_COMPILE >= OCI_9_0
    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, type, LobTypeValues, OTEXT("Lob type"))
#endif

    call_status = OCI_BindData(stmt, NULL, sizeof(OCILobLocator*), name, OCI_CDT_LOB,
                               OCI_ExternalSubTypeToSQLType(OCI_CDT_LOB, type),
                               OCI_BIND_OUTPUT, type, NULL, 0);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterFile
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterFile
(
    OCI_Statement *stmt,
    const otext   *name,
    unsigned int   type
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_REGISTER_CALL(stmt, name)
    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, type, FileTypeValues, OTEXT("File type"))

    call_status =  OCI_BindData(stmt, NULL, sizeof(OCILobLocator*), name, OCI_CDT_FILE,
                                OCI_ExternalSubTypeToSQLType(OCI_CDT_FILE, type),
                                OCI_BIND_OUTPUT, type, NULL, 0);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_RegisterRef
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_RegisterRef
(
    OCI_Statement *stmt,
    const otext   *name,
    OCI_TypeInfo  *typinf
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_REGISTER_CALL(stmt, name)
    OCI_CHECK_PTR(OCI_IPC_TYPE_INFO, typinf)

    call_status = OCI_BindData(stmt, NULL, sizeof(OCIRef *), name, OCI_CDT_REF,
                               SQLT_REF, OCI_BIND_OUTPUT, 0, typinf, 0);

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetStatementType
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetStatementType
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, OCI_UNKNOWN)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->type;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_SetFetchMode
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_SetFetchMode
(
    OCI_Statement *stmt,
    unsigned int   mode
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_SCROLLABLE_CURSOR_ENABLED(stmt->con)
    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, mode, FetchModeValues, OTEXT("Fetch mode"))

    stmt->exec_mode = mode;

    call_retval = call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetFetchMode
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetFetchMode
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, OCI_UNKNOWN)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->exec_mode;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_SetBindMode
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_SetBindMode
(
    OCI_Statement *stmt,
    unsigned int   mode
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, mode, BindModeValues, OTEXT("Bind mode"))

    stmt->bind_mode = mode;

    call_retval = call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetBindMode
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetBindMode
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, OCI_UNKNOWN)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->bind_mode;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_SetBindAllocation
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_SetBindAllocation
(
    OCI_Statement *stmt,
    unsigned int   mode
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, mode, BindAllocationValues, OTEXT("Bind Allocation"))

    stmt->bind_alloc_mode = mode;

    call_retval = call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetBindAllocation
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetBindAllocation
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, OCI_UNKNOWN)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->bind_alloc_mode;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_SetFetchSize
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_SetFetchSize
(
    OCI_Statement *stmt,
    unsigned int   size
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_MIN(stmt->con, stmt, size, 1)

    stmt->fetch_size = size;

    call_retval = call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetFetchSize
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetFetchSize
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, 0)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->fetch_size;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * "PrefetchSize
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_SetPrefetchSize
(
    OCI_Statement *stmt,
    unsigned int   size
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_status = TRUE;

    stmt->prefetch_size = size;

    if (stmt->stmt)
    {
        OCI_CALL1
        (
            call_status, stmt->con, stmt,

            OCIAttrSet((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT,
                       (dvoid *) &stmt->prefetch_size,
                       (ub4) sizeof(stmt->prefetch_size),
                       (ub4) OCI_ATTR_PREFETCH_ROWS, stmt->con->err)
        )
    }

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetPrefetchSize
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetPrefetchSize
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, 0)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->prefetch_size;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_SetPrefetchMemory
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_SetPrefetchMemory
(
    OCI_Statement *stmt,
    unsigned int   size
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_status = TRUE;

    stmt->prefetch_mem = size;

    if (stmt->stmt)
    {
        OCI_CALL1
        (
            call_status, stmt->con, stmt,

            OCIAttrSet((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT,
                       (dvoid *) &stmt->prefetch_mem,
                       (ub4) sizeof(stmt->prefetch_mem),
                       (ub4) OCI_ATTR_PREFETCH_MEMORY, stmt->con->err)
        )
    }

    call_retval = call_status;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetPrefetchMemory
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetPrefetchMemory
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, 0)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->prefetch_mem;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_SetLongMaxSize
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_SetLongMaxSize
(
    OCI_Statement *stmt,
    unsigned int   size
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_MIN(stmt->con, stmt, size, 1)

    stmt->long_size = size;

    call_retval = call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetLongMaxSize
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetLongMaxSize
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, 0)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->long_size;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_SetLongMode
 * --------------------------------------------------------------------------------------------- */

boolean OCI_API OCI_SetLongMode
(
    OCI_Statement *stmt,
    unsigned int   mode
)
{
    OCI_LIB_CALL_ENTER(boolean, FALSE)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    OCI_CHECK_ENUM_VALUE(stmt->con, stmt, mode, LongModeValues, OTEXT("Long Mode"))

    stmt->long_mode = (ub1) mode;

    call_retval = call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetLongMode
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetLongMode
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, OCI_UNKNOWN)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->long_mode;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_StatementGetConnection
 * --------------------------------------------------------------------------------------------- */

OCI_Connection * OCI_API OCI_StatementGetConnection
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(OCI_Connection*, NULL)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->con;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetSql
 * --------------------------------------------------------------------------------------------- */

const otext * OCI_API OCI_GetSql
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(const otext*, NULL)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->sql;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()

}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetSqlErrorPos
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetSqlErrorPos
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, 0)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->err_pos;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetAffecteddRows
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetAffectedRows
(
    OCI_Statement *stmt
)
{
    ub4 count = 0;

    OCI_LIB_CALL_ENTER(unsigned int, count)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_status = TRUE;

    OCI_CALL1
    (
        call_status, stmt->con, stmt,

        OCIAttrGet((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT,
                   (void *) &count, (ub4 *) NULL, (ub4) OCI_ATTR_ROW_COUNT,
                   stmt->con->err)
    )

    call_retval = count;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetBindCount
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetBindCount
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, 0)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    call_retval = stmt->nb_ubinds;
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetBind
 * --------------------------------------------------------------------------------------------- */

OCI_Bind * OCI_API OCI_GetBind
(
    OCI_Statement *stmt,
    unsigned int   index
)
{
    OCI_LIB_CALL_ENTER(OCI_Bind*, NULL)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_BOUND(stmt->con, index, 1, stmt->nb_ubinds)

    call_retval = stmt->ubinds[index - 1];
    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetBind2
 * --------------------------------------------------------------------------------------------- */

OCI_Bind * OCI_API OCI_GetBind2
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    OCI_Bind *bnd = NULL;
    int index = -1;

    OCI_LIB_CALL_ENTER(OCI_Bind*, NULL)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_PTR(OCI_IPC_STRING, name)

    index = OCI_BindGetInternalIndex(stmt, name);

    if (index > 0)
    {
        bnd = stmt->ubinds[index-1];
    }
    else
    {
        OCI_ExceptionItemNotFound(stmt->con, stmt, name, OCI_IPC_BIND);
    }

    if (bnd)
    {
        call_retval = bnd;
        call_status = TRUE;
    }

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
* OCI_GetBindIndex
* --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetBindIndex
(
    OCI_Statement *stmt,
    const otext   *name
)
{
    int index = -1;

    OCI_LIB_CALL_ENTER(unsigned int, 0)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_PTR(OCI_IPC_STRING, name)

    index = OCI_BindGetInternalIndex(stmt, name);

    if (index >= 0)
    {
        call_status = TRUE;
    }
    else
    {
        index = 0;
    }


    call_retval = index;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetSQLCommand
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetSQLCommand
(
    OCI_Statement *stmt
)
{
    ub2 code = OCI_UNKNOWN;

    OCI_LIB_CALL_ENTER(unsigned int, code)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)
    OCI_CHECK_STMT_STATUS(stmt, OCI_STMT_EXECUTED)

    call_status = TRUE;

    OCI_CALL1
    (
        call_status, stmt->con, stmt,

        OCIAttrGet((dvoid *) stmt->stmt, (ub4) OCI_HTYPE_STMT,
                   (dvoid *) &code, (ub4 *) NULL,
                   (ub4) OCI_ATTR_SQLFNCODE, stmt->con->err)
    )

    call_retval = code;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetSQLVerb
 * --------------------------------------------------------------------------------------------- */

const otext * OCI_API OCI_GetSQLVerb
(
    OCI_Statement *stmt
)
{
    unsigned int code = OCI_UNKNOWN;

    OCI_LIB_CALL_ENTER(const otext *, NULL)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    code = OCI_GetSQLCommand(stmt);

    if (OCI_UNKNOWN != code)
    {
        int i;

        for (i = 0; i < OCI_SQLCMD_COUNT; i++)
        {
            if (code == SQLCmds[i].code)
            {
                call_retval = SQLCmds[i].verb;
                break;
            }
        }
    }

    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetBatchError
 * --------------------------------------------------------------------------------------------- */

OCI_Error * OCI_API OCI_GetBatchError
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(OCI_Error*, NULL)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    if (stmt->batch)
    {
        if (stmt->batch->cur < stmt->batch->count)
        {
            call_retval = &stmt->batch->errs[stmt->batch->cur++];
        }
    }

    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

/* --------------------------------------------------------------------------------------------- *
 * OCI_GetBatchErrorCount
 * --------------------------------------------------------------------------------------------- */

unsigned int OCI_API OCI_GetBatchErrorCount
(
    OCI_Statement *stmt
)
{
    OCI_LIB_CALL_ENTER(unsigned int, 0)

    OCI_CHECK_PTR(OCI_IPC_STATEMENT, stmt)

    if (stmt->batch)
    {
        call_retval = stmt->batch->count;
    }

    call_status = TRUE;

    OCI_LIB_CALL_EXIT()
}

