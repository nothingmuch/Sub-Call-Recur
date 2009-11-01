package Sub::Call::Recur;

use strict;
use warnings;

require 5.008001;
use parent qw(Exporter DynaLoader);
use B::Hooks::OP::Check::EntersubForCV;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

our @EXPORT = our @EXPORT_OK = qw(recur);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

__PACKAGE__->bootstrap($VERSION);

pop our @ISA;

# ex: set sw=4 et:

__PACKAGE__

__END__
