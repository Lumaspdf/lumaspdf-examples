<?php
/**
 * LumasReport from PHP: engine -> open -> parameters -> render -> export.
 *
 * The reporting engine is licensed separately from the PDF engine, and every
 * call that can fail throws LumasReportException carrying the engine's own
 * code / module / message / hint.
 */
require __DIR__ . '/../bootstrap.php';

if (!class_exists('LumasReport')) { say('LumasRpt.php not present'); exit(0); }

[$maj, $min, $pat] = LumasReport::version();
say("LumasReport $maj.$min.$pat");

try {
    // Both licence keys are optional: without them the engine runs
    // full-featured and marks its output.
    $rpt = new LumasReport(getenv('LUMASRPT_LICENSE_KEY') ?: null,
                           getenv('LUMASPDF_LICENSE_KEY') ?: null);

    $job = $rpt->openReport(__DIR__ . '/hello_report.lrpt');
    $job->setParams(['customer' => 'ACME Ltd'])
        ->render();

    say('pages rendered: ' . $job->pageCount());

    $out = out_path('hello_report.pdf');
    $job->export(LumasReport::EXP_PDF, $out);
    $job->export(LumasReport::EXP_HTML, out_path('hello_report.html'));
    $job->close();
    done($out);
} catch (LumasReportException $e) {
    // The engine's own diagnosis, not a generic "returned 0".
    say('reporting failed: ' . $e->getMessage());
    exit(1);
}
