#
# Copyright (c) 2008 Klaas Freitag <freitag@suse.de>, Novell Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
################################################################
# Contributors:
#  Klaas Freitag <freitag@suse.de>
#
package Hermes::Delivery::Mail;

use strict;
use Exporter;

use Data::Dumper;
use MIME::Lite;

use Hermes::Config;
use Hermes::DBI;
use Hermes::Log;
use Hermes::Person;

use vars qw( @ISA @EXPORT @EXPORT_OK );

@ISA	    = qw(Exporter);
@EXPORT	    = qw( sendMail );

#
# Send a message by mail.
#  from       => Sender Address as String
#  to         => Array ref of person ids
#  cc         => Array ref of person ids
#  bcc        => Array ref of person ids
#  replyto    => same as sender FIXME !
#  subject    => string
#  body       => string
#  debug      => debug flag, true if debug.
# 
sub sendMail( $ )
{
  my ($msg) = @_;

  my $mime_msg = MIME::Lite->new( From	  => $msg->{from},
				  Subject => $msg->{subject},
				  Data    => $msg->{body} );

  # FIXME: Parametercheck.

  # get the emails out of the person module
  my @t;
  foreach my $p ( @{$msg->{to} } ) {
    my $pInfoRef = personInfo( $p );
    push @t, $pInfoRef->{email};
  }

  my $toLine = join( ', ', @t );
  log( 'info', "To-line: $toLine" );
  $mime_msg->add('To' => $toLine );

  @t = ();
  foreach my $p ( @{$msg->{cc} } ) {
    my $pInfoRef = personInfo( $p );
    push @t, $pInfoRef->{email};
  }
  $mime_msg->add('Cc' => join( ', ', @t ) );

  @t = ();
  foreach my $p ( @{$msg->{bcc} } ) {
    my $pInfoRef = personInfo( $p );
    push @t, $pInfoRef->{email};
  }
  $mime_msg->add('Bcc' => join( ', ', @t ) );

  $mime_msg->add('reply-to' => $msg->{replyto} ) if( $msg->{replyto} );
  $mime_msg->add('X-hermes-msg-type:' => $msg->{type} ) if( $msg->{type} );
  $mime_msg->replace('X-Mailer' => 'openSUSE Notification System');

  # Send the message.
  if ($msg->{debug} ) {
    print STDERR "[ Hermes Mail Module Debug: Start of MIME-encoded message ]\n";
    print STDERR $mime_msg->as_string;
    print STDERR "\n[ Hermes Mail Module Debug: End of MIME-encoded message ]\n";
  } else {
    $mime_msg->send();
  }

  1;
}

1;