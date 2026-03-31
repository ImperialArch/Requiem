#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use threads;
use Thread::Queue;
use threads::shared;
use Getopt::Long;
use JSON;

my $concurrency = 12;
my $output = "";
my @results : shared;

GetOptions(
    "concurrency=i" => \$concurrency,
    "output=s" => \$output,
);

my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0');
$ua->max_redirect(5);

my $url = $ARGV[0];
my $response = $ua->get($url);


my $fileHandle_lock : shared;

if ($response->is_success) {
    my $content = $response->decoded_content;
    my @links = grep { 
    $_ !~ /^#/ && 
    $_ !~ /^mailto:/ && 
    $_ !~ /^javascript:/ &&
    $_ =~ /^https?:\/\//
    } ($content =~ /href="([^"]*)"/g);

    my $queue = Thread::Queue->new();
    $queue->enqueue(@links);
    $queue->end();

my $dead_links : shared = 0;
my $unreachable_links : shared = 0;

my $fileHandle;

if ($output) {
        open($fileHandle, '>', $output . ".json") or die "Cannot create file: $!";
}

    my @workers = map {
        threads->create(sub {
            while (my $links = $queue->dequeue()) {
                my $req = $ua->head($links);
                if ($req->code =~ /^(405|501)/) {
                    $req = $ua->get($links);
                }

                if ($req->code == 500 && $links =~ /web\.archive\.org/) {
                     my $result = {
                        url => $links,
                        status => $req->status_line,
                        type => "unreachable"
                    };
                    lock(@results);
                    push @results, shared_clone($result);
                    lock($unreachable_links);
                    $unreachable_links++;
                } elsif ($req->code !~ /^(2|500)/) {
                    my $result = {
                        url => $links,
                        status => $req->status_line,
                        type => "dead"
                    };
                    lock(@results);
                    push @results, shared_clone($result);
                    lock($dead_links);
                    $dead_links++;
                }
            }
        })
    }1..$concurrency;

    $_->join() for @workers;

    if ($fileHandle) {
        print $fileHandle to_json(\@results, { pretty => 1 });
    }

    print "Total Links: " . scalar(@links) . "\n";
    print "Unreachable Links: " . $unreachable_links . "\n";
    print "Dead Links: " . $dead_links . "\n";

} else {
    print "Error: " . $response->status_line . "\n";
}

