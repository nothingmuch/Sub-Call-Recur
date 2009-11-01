/* ex: set sw=4 et: */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hook_op_check_entersubforcv.h"


#define MY_CXT_KEY "Sub::Call::Recur::_guts" XS_VERSION

typedef struct {
    OP fakeop;
} my_cxt_t;

START_MY_CXT


static OP *recur () {
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
        OP *nextop;

        SvREFCNT_inc_simple_void_NN(cv);
        sv_2mortal(cv);

        /* discard the CV of recur itself, that would have been given to entersub */
        POPs;
        PUTBACK;

        /* execute return in list context, unwinding the stack and leaving the
         * return values on the argument stack */
        cx->blk_gimme = G_ARRAY;
        MY_CXT.fakeop.op_next = PL_ppaddr[OP_RETURN](aTHX);
        SPAGAIN;

        /* add the CV of the sub we just returned from */
        XPUSHs((SV *)cv);
        PUTBACK;

        /* mark the first return value */
        PUSHMARK(SP - items);

        /* make a call to that subroutine, with the return values serving as args,
         * and PL_op->op_next pointing to the original retop */

        PL_op = &MY_CXT.fakeop;
        nextop = PL_ppaddr[OP_ENTERSUB](aTHX);

        /* restore context */
        cxstack[cxstack_ix].blk_gimme = gimme;

        MY_CXT.fakeop.op_next = NULL;

        return nextop;
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

    MY_CXT_INIT;

    Zero(&MY_CXT.fakeop, 1, OP);

    MY_CXT.fakeop.op_type  = OP_ENTERSUB;
    MY_CXT.fakeop.op_flags = OPf_STACKED | OPf_WANT_VOID;
}
