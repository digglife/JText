package JText;

BEGIN {
    $JText::VERSION = '0.1';
}

use strict;
use warnings;
use URI::Escape;
use LWP::UserAgent;
use XML::Simple;

use constant {
    MA_URL        => 'http://jlp.yahooapis.jp/MAService/V1/parse',
    JIM_URL       => 'http://jlp.yahooapis.jp/JIMService/V1/conversion',
    FURIGANA_URL  => 'http://jlp.yahooapis.jp/FuriganaService/V1/furigana',
    KOUSEI_URL    => 'http://jlp.yahooapis.jp/KouseiService/V1/kousei',
    DA_URL        => 'http://jlp.yahooapis.jp/DAService/V1/parse',
    KEYPHRASE_URL => 'http://jlp.yahooapis.jp/KeyphraseService/V1/extract',
};

sub new {
    my ( $class, $appid ) = @_;
    my $self->{'appid'} = $appid;

    bless $self, $class;
    return $self;
}

sub _request {
    my ( $self, $base, $sentence, $options, $known_options ) = @_;

    my $params = {
        'appid'    => $self->{'appid'},
        'sentence' => $sentence,
    };

    for my $key ( keys %$options ) {
        if ( grep { $key eq $_ } @$known_options ) {
            $params->{$key} = $options->{$key};
        }
        else {
            die "Not valid option $key.\n";
        }
    }

    my $url =
      $base . '?'
      . join( '&',
        map { join( '=', $_, uri_escape( $params->{$_} ) ) } keys %$params );

    my $ua   = LWP::UserAgent->new();
    my $resp = $ua->get($url);

    my $content;
    if ( $resp->is_success ) {
        $content = $resp->decoded_content();
    }
    else {
        die "Unable to open $url, ",$resp->status_line;
    }

    #return encode_utf8($content);
    return $content;
}

sub ma {
    my ( $self, $sentence, $options ) = @_;
    my $known_options = [
        'results',       'response',    'filter', 'ma_response',
        'uniq_response', 'uniq_filter', 'uniq_by_baseform',
    ];
    my $content =
      $self->_request( MA_URL, $sentence, $options, $known_options );

    return XMLin( $content, ForceArray => ['Word'] );
}

sub jim {
    my ( $self, $sentence, $options ) = @_;
    my $known_options =
      [ 'format', 'mode', 'response', 'dictionary', 'results' ];
    my $content =
      $self->_request( JIM_URL, $sentence, $options, $known_options );

    return XMLin( $content, ForceArray => [ 'Segment', 'Candidate' ] );
}

sub furigana {
    my ( $self, $sentence, $options ) = @_;
    my $known_options = ['grade'];
    my $content =
      $self->_request( FURIGANA_URL, $sentence, $options, $known_options );

    return XMLin( $content, ForceArray => ['Word'] );
}

sub kousei {
    my ( $self, $sentence, $options ) = @_;
    my $known_options = [ 'filter_group', 'no_filter' ];
    my $content =
      $self->_request( KOUSEI_URL, $sentence, $options, $known_options );

    return XMLin( $content, ForceArray => ['result'] );

}

sub da {
    my ( $self, $sentence ) = @_;
    my $content = $self->_request( DA_URL, $sentence );

    return XMLin( $content, ForceArray => [ 'Chunk', 'Morphem' ] );
}

sub keyphrase {
    my ( $self, $sentence, $options ) = @_;
    my $known_options = [ 'output', 'callback' ];
    my $content =
      $self->_request( KEYPHRASE_URL, $sentence, $options, $known_options );

    return XMLin( $content, ForceArray => ['result'] );
}

1;

__END__

=head1 NAME

WWW::Yahoo::JText - Simple Module for Yahoo! Japan Text Parser API
