<?php
/**
 * Run every example and report pass/fail. Each example runs in its own
 * process, in its own directory, so one failure cannot mask another.
 *
 *   php run_all.php
 */
declare(strict_types=1);

$root = __DIR__;
$php  = PHP_BINARY;
$files = [];
foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root)) as $f) {
    $p = $f->getPathname();
    if (substr($p, -4) !== '.php') continue;
    $base = basename($p);
    if (in_array($base, ['run_all.php', 'bootstrap.php'], true)) continue;
    $norm = str_replace(DIRECTORY_SEPARATOR, '/', $p);
    if (strpos($norm, '/out/') !== false) continue;
    // dyna_compat/ holds the vendor's own example sources, used only to prove
    // the compatibility shim. They need that shim, they are not ours to ship,
    // and they have their own runner.
    if (strpos($norm, '/dyna_compat/') !== false) continue;
    $files[] = $p;
}
sort($files);

$pass = $fail = 0;
foreach ($files as $f) {
    $dir = dirname($f);
    $cmd = escapeshellarg($php) . ' ' . escapeshellarg(basename($f));
    $old = getcwd();
    chdir($dir);
    exec($cmd, $lines, $rc);
    chdir($old);
    $rel = str_replace(DIRECTORY_SEPARATOR, '/', substr($f, strlen($root) + 1));
    if ($rc === 0) { $pass++; printf("PASS  %s\n", $rel); }
    else {
        $fail++;
        printf("FAIL  %s  (exit %d)\n", $rel, $rc);
        foreach (array_slice($lines, 0, 4) as $l) echo '        ', rtrim($l), "\n";
    }
    $lines = [];
}
printf("\n%d passed, %d failed, %d total\n", $pass, $fail, $pass + $fail);
exit($fail === 0 ? 0 : 1);
