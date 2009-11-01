/* ex: set sw=4 et: */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hook_op_check_entersubforcv.h"



#ifndef AvREIFY_only
#define AvREIFY_only(av)	(AvREIFY_off(av), AvREAL_on(av))
#endif

static OP *recur (pTHX) {
    dVAR; dSP; dMARK; dITEMS;

    IV cxix = cxstack_ix;
    PERL_CONTEXT *cx = NULL;

    while ( cxix > 0 ) {
        if ( CxTYPE(&cxstack[cxix]) == CXt_SUB ) {
            cx = &cxstack[cxix];
            break;
        } else {
            cxix--;
        }
    }
    
    if (cx == NULL) {
        DIE(aTHX_ "Can't recur outside a subroutine");
    } else {
        CV *cv = cx->blk_sub.cv;
        I32 gimme = cx->blk_gimme;
        AV *av = cx->blk_sub.argarray;

        POPs; /* discard the CV for recur itself */
        PUTBACK;

        items--;

        /* undwind to top level */
        if ( cxix < cxstack_ix )
            dounwind(cxix);

        /* abandon @_ if it got reified */
        if (AvREAL(av)) {
            SvREFCNT_dec(av);
            av = newAV();
            AvREIFY_only(av);

            cx->blk_sub.argarray = av;
            PAD_SVl(0) = (SV *)av;
        }

        ++MARK;

        av_extend(av, items-1);

        Copy(MARK,AvARRAY(av),items,SV*);
        AvFILLp(av) = items - 1;

        while (MARK <= SP) {
            if (*MARK) {
                if ( SvTEMP(*MARK) || SvPADMY(*MARK) ) {
                    I32 key;

                    key = AvMAX(av) + 1;
                    while (key > AvFILLp(av) + 1)
                        AvARRAY(av)[--key] = &PL_sv_undef;
                    while (key) {
                        SV * const sv = AvARRAY(av)[--key];
                        assert(sv);
                        if (sv != &PL_sv_undef)
                            SvREFCNT_inc_simple_void_NN(sv);
                    }
                    key = AvARRAY(av) - AvALLOC(av);
                    while (key)
                        AvALLOC(av)[--key] = &PL_sv_undef;
                    AvREIFY_off(av);
                    AvREAL_on(av);

                    break;
                }
            }
            MARK++;
        }

        LEAVE;
        ENTER;

        RETURNOP(CvSTART(cv));
    }
}

STATIC OP *install_recur_op (pTHX_ OP *o, CV *cv, void *user_data) {
    o->op_ppaddr = recur;
    return o;
}

MODULE = Sub::Call::Recur        PACKAGE = Sub::Call::Recur
PROTOTYPES: disable

BOOT:
{
    hook_op_check_entersubforcv(get_cv("Sub::Call::Recur::recur", TRUE), install_recur_op, NULL);
}
