<?php
/**
 * Shared bootstrap for the LumasPDF PHP examples.
 *
 * It locates the binding and the engine WITHOUT any absolute path, so the
 * same file works from the unpacked package, from a Composer install and from
 * a source checkout:
 *
 *   package layout     php/LumasPdf.php          php/examples/<topic>/x.php
 *   source checkout    wrappers/php/LumasPdf.php examples/php/<topic>/x.php
 *
 * The engine is found by LumasPdf::libraryCandidates() -- next to
 * LumasPdf.php, or in bin/<platform>/, or wherever $LUMASPDF_LIB_DIR points.
 */

declare(strict_types=1);

$__here = __DIR__;
$__try  = [];
for ($d = $__here, $i = 0; $i < 5; $i++, $d = dirname($d)) {
    $__try[] = $d . '/LumasPdf.php';                 // package: php/examples/*/..
    $__try[] = $d . '/wrappers/php/LumasPdf.php';    // source checkout
}
$__found = null;
foreach ($__try as $__c) { if (is_file($__c)) { $__found = $__c; break; } }
if ($__found === null) {
    fwrite(STDERR, "LumasPdf.php not found. Looked in:\n  " .
                   implode("\n  ", $__try) . "\n");
    exit(2);
}
require_once $__found;
require_once dirname($__found) . '/LumasPdfOO.php';
if (is_file(dirname($__found) . '/LumasRpt.php'))
    require_once dirname($__found) . '/LumasRpt.php';

/** Directory this example writes its output to (created on demand). */
function out_dir(): string
{
    $d = getenv('LUMASPDF_OUT_DIR') ?: (getcwd() . DIRECTORY_SEPARATOR . 'out');
    if (!is_dir($d)) @mkdir($d, 0777, true);
    return rtrim($d, '/\\');
}

function out_path(string $name): string
{
    return out_dir() . DIRECTORY_SEPARATOR . $name;
}

/**
 * Candidate test_files/ directories, nearest first.
 *   package layout   php/test_files/
 *   source checkout  examples/test_files/ and ship/_fixtures/
 */
function test_dirs(): array
{
    $dirs = [];
    if ($env = getenv('LUMASPDF_TEST_FILES')) $dirs[] = rtrim($env, "/\\");
    for ($d = __DIR__, $i = 0; $i < 6; $i++, $d = dirname($d)) {
        $dirs[] = $d . '/test_files';
        $dirs[] = $d . '/ship/_fixtures';
    }
    return array_values(array_unique(array_filter($dirs, 'is_dir')));
}

function test_files(): string
{
    $d = test_dirs();
    return $d ? $d[0] : __DIR__;
}

/** Full path of a fixture -- the FIRST candidate directory that has it. */
function test_file(string $name): string
{
    foreach (test_dirs() as $d) {
        $p = $d . DIRECTORY_SEPARATOR . $name;
        if (is_file($p)) return $p;
    }
    return test_files() . DIRECTORY_SEPARATOR . $name;   // report a real path
}

/** A document with the error callback already wired -- always start here. */
function new_doc(): LumasPdfOO
{
    $pdf = new LumasPdfOO();
    // Licence: without one the engine runs full-featured and marks its output.
    if ($key = getenv('LUMASPDF_LICENSE_KEY')) $pdf->SetLicenseKey($key);
    return $pdf;
}

function say(string $msg): void { echo $msg, PHP_EOL; }

function done(string $file): void
{
    $ok = is_file($file) && filesize($file) > 0;
    say(($ok ? 'OK   ' : 'FAIL ') . $file . ($ok ? '  (' . filesize($file) . ' bytes)' : ''));
    if (!$ok) exit(1);
}

/**
 * Pack an RGB colour the way the engine expects: 0x00BBGGRR.
 * (PDF_RED is 0x0000FF and PDF_BLUE is 0xFF0000 -- red sits in the LOW byte.
 * The PDF_RGB composing macro is one of the documented header gaps, so every
 * binding needs its own.)
 */
function rgb(int $r, int $g, int $b): int
{
    return ($r & 0xFF) | (($g & 0xFF) << 8) | (($b & 0xFF) << 16);
}

/** Pack a CMYK colour: 0xKKYYMMCC, each component 0..255. */
function cmyk(int $c, int $m, int $y, int $k): int
{
    return ($c & 0xFF) | (($m & 0xFF) << 8) | (($y & 0xFF) << 16) | (($k & 0xFF) << 24);
}
