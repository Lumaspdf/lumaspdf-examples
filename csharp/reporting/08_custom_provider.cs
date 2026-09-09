//  08_custom_provider -- C# port of examples\Vb6\reporting\08_custom_provider.bas
//  Registers a native data provider (VTable of function pointers) exposing an
//  in-memory 4-row x 5-typed-column table, then renders it.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class CustomProvider08
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    const int vkNull = 0, vkBool = 1, vkInt = 2, vkFloat = 3, vkDate = 4, vkStr = 5;

    static IntPtr mPdf;
    static IntPtr mEng;

    // --- provider VTable delegate types (stdcall) ---
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int OpenFn(IntPtr U, IntPtr Conn, IntPtr Query, IntPtr Params, int NParams, out IntPtr Cursor);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int GetSchemaFn(IntPtr Cursor, IntPtr Fields, int MaxFields);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int FetchFn(IntPtr Cursor);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int GetValFn(IntPtr Cursor, int Field, IntPtr V);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate void CloseFn(IntPtr Cursor);

    // keep the delegate instances alive for the lifetime of the process
    static OpenFn _open = MyOpen;
    static GetSchemaFn _getSchema = MyGetSchema;
    static FetchFn _fetch = MyFetch;
    static GetValFn _getVal = MyGetVal;
    static CloseFn _close = MyClose;

    // in-memory table
    static int[] mRowId = new int[4];
    static double[] mPrice = new double[4];
    static int[] mActive = new int[4];
    static bool[] mHasNote = new bool[4];
    static IntPtr[] mNamePtr = new IntPtr[4]; // persistent ANSI buffers
    static IntPtr[] mNotePtr = new IntPtr[4];
    static string[] mFieldName = new string[5];
    static int[] mFieldKind = new int[5];

    static void WriteText(string path, string content) { File.WriteAllText(path, content); }

    static void DumpRptError(IntPtr eng)
    {
        IntPtr p = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(TRptErrorInfoC)));
        try
        {
            if (LumasPdf.rptGetLastError(eng, p))
            {
                var info = (TRptErrorInfoC)Marshal.PtrToStructure(p, typeof(TRptErrorInfoC));
                if (info.Code != 0)
                    Console.WriteLine("  ! rpt error " + info.Code + " [" + info.Module_ + "] at " + info.Location + ": " + info.Msg);
            }
        }
        finally { Marshal.FreeHGlobal(p); }
    }

    static bool BootEngine()
    {
        mPdf = LumasPdf.pdfNewPDF();
        if (mPdf == IntPtr.Zero) { Console.WriteLine("pdfNewPDF failed"); return false; }
        LumasPdf.pdfSetLicenseKey(mPdf, PDF_DEMO_KEY);
        LumasPdf.rptSetRptLicenseKeyA(mPdf, RPT_DEMO_KEY);
        mEng = LumasPdf.rptCreateEngineA(mPdf, null);
        if (mEng == IntPtr.Zero) { Console.WriteLine("rptCreateEngine failed:"); DumpRptError(IntPtr.Zero); return false; }
        return true;
    }

    // --- provider callbacks ---
    static int MyOpen(IntPtr U, IntPtr Conn, IntPtr Query, IntPtr Params, int NParams, out IntPtr Cursor)
    {
        IntPtr p = Marshal.AllocHGlobal(4);
        Marshal.WriteInt32(p, -1);
        Cursor = p;
        return 0;
    }

    static int MyGetSchema(IntPtr Cursor, IntPtr Fields, int MaxFields)
    {
        int n = 5;
        if (n > MaxFields) n = MaxFields;
        for (int i = 0; i < n; i++)
        {
            var fd = new TRptCFieldDef();
            fd.Name = mFieldName[i];
            fd.Kind = mFieldKind[i];
            IntPtr dst = new IntPtr(Fields.ToInt64() + (long)i * 68);
            Marshal.StructureToPtr(fd, dst, false);
        }
        return n;
    }

    static int MyFetch(IntPtr Cursor)
    {
        int r = Marshal.ReadInt32(Cursor);
        r = r + 1;
        Marshal.WriteInt32(Cursor, r);
        return (r <= 3) ? 1 : 0;
    }

    static int MyGetVal(IntPtr Cursor, int Field, IntPtr V)
    {
        int r = Marshal.ReadInt32(Cursor);
        var cv = new TRptCValue();
        cv.Kind = vkNull; cv.B = 0; cv.I = 0; cv.F = 0; cv.S = IntPtr.Zero;
        switch (Field)
        {
            case 0:
                cv.Kind = vkInt; cv.I = mRowId[r];
                break;
            case 1:
                cv.Kind = vkFloat; cv.F = mPrice[r];
                break;
            case 2:
                cv.Kind = vkStr; cv.S = mNamePtr[r];
                break;
            case 3:
                cv.Kind = vkBool; cv.B = mActive[r];
                break;
            case 4:
                if (!mHasNote[r]) cv.Kind = vkNull;
                else { cv.Kind = vkStr; cv.S = mNotePtr[r]; }
                break;
            default:
                cv.Kind = vkNull;
                break;
        }
        Marshal.StructureToPtr(cv, V, false);
        return 0;
    }

    static void MyClose(IntPtr Cursor)
    {
        if (Cursor != IntPtr.Zero) Marshal.FreeHGlobal(Cursor);
    }

    static void Main()
    {
        if (!BootEngine()) return;

        // In-memory table: 4 rows x 5 typed columns.
        mRowId[0] = 1; mRowId[1] = 2; mRowId[2] = 3; mRowId[3] = 4;
        mPrice[0] = 12.5; mPrice[1] = 9.99; mPrice[2] = 0; mPrice[3] = 47.75;
        mActive[0] = 1; mActive[1] = 0; mActive[2] = 1; mActive[3] = 1;
        mHasNote[0] = true; mHasNote[1] = true; mHasNote[2] = false; mHasNote[3] = true;
        mNamePtr[0] = Marshal.StringToHGlobalAnsi("Alpha");
        mNamePtr[1] = Marshal.StringToHGlobalAnsi("Beta");
        mNamePtr[2] = Marshal.StringToHGlobalAnsi("Gamma");
        mNamePtr[3] = Marshal.StringToHGlobalAnsi("Delta");
        mNotePtr[0] = Marshal.StringToHGlobalAnsi("first");
        mNotePtr[1] = Marshal.StringToHGlobalAnsi("second");
        mNotePtr[2] = IntPtr.Zero;
        mNotePtr[3] = Marshal.StringToHGlobalAnsi("fourth");
        mFieldName[0] = "Id"; mFieldKind[0] = vkInt;
        mFieldName[1] = "Price"; mFieldKind[1] = vkFloat;
        mFieldName[2] = "Name"; mFieldKind[2] = vkStr;
        mFieldName[3] = "Active"; mFieldKind[3] = vkBool;
        mFieldName[4] = "Note"; mFieldKind[4] = vkStr;

        var vt = new TRptProviderVTable();
        vt.Open = Marshal.GetFunctionPointerForDelegate(_open);
        vt.GetSchema = Marshal.GetFunctionPointerForDelegate(_getSchema);
        vt.Fetch = Marshal.GetFunctionPointerForDelegate(_fetch);
        vt.GetVal = Marshal.GetFunctionPointerForDelegate(_getVal);
        vt.RewindC = IntPtr.Zero;
        vt.RowCount = IntPtr.Zero;
        vt.Exec = IntPtr.Zero;
        vt.Tx = IntPtr.Zero;
        vt.CloseC = Marshal.GetFunctionPointerForDelegate(_close);

        IntPtr vtp = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(TRptProviderVTable)));
        Marshal.StructureToPtr(vt, vtp, false);

        if (!LumasPdf.rptRegisterProvider(mEng, "mydata", vtp, IntPtr.Zero))
        {
            Console.WriteLine("register provider failed"); DumpRptError(mEng); goto Cleanup;
        }

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string Lrpt = Path.Combine(dir, "08_custom.lrpt");
        string OutPdf = Path.Combine(dir, "08_custom.pdf");
        string OutTxt = Path.Combine(dir, "08_custom.txt");

        string Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"CustomProvider\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        Xml += " <datasources><datasource alias=\"d\" provider=\"mydata\" conn=\"\" query=\"\"/></datasources>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"reportheader\" name=\"rh\" height=\"12\">\n";
        Xml += "   <text name=\"t\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\" wordWrap=\"0\">Custom Provider - typed rows</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"pageheader\" name=\"ph\" height=\"7\">\n";
        Xml += "   <text name=\"h1\" x=\"0\"   y=\"0\" w=\"20\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">Id</text>\n";
        Xml += "   <text name=\"h2\" x=\"22\"  y=\"0\" w=\"40\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">Name</text>\n";
        Xml += "   <text name=\"h3\" x=\"64\"  y=\"0\" w=\"30\" h=\"5\" fontSize=\"9\" bold=\"1\" hAlign=\"right\" wordWrap=\"0\">Price</text>\n";
        Xml += "   <text name=\"h4\" x=\"98\"  y=\"0\" w=\"24\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">Active</text>\n";
        Xml += "   <text name=\"h5\" x=\"126\" y=\"0\" w=\"50\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">Note</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n";
        Xml += "   <text name=\"c1\" x=\"0\"   y=\"0\" w=\"20\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{Id}}</text>\n";
        Xml += "   <text name=\"c2\" x=\"22\"  y=\"0\" w=\"40\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{Name}}</text>\n";
        Xml += "   <text name=\"c3\" x=\"64\"  y=\"0\" w=\"30\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Price) }}</text>\n";
        Xml += "   <text name=\"c4\" x=\"98\"  y=\"0\" w=\"24\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{expr: CSTR(Active) }}</text>\n";
        Xml += "   <text name=\"c5\" x=\"126\" y=\"0\" w=\"50\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{expr: IFNULL(Note, '(none)') }}</text>\n";
        Xml += "  </band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        WriteText(Lrpt, Xml);

        IntPtr Job = LumasPdf.rptOpenReportA(mEng, Lrpt);
        if (Job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(mEng); goto Cleanup; }
        if (!LumasPdf.rptRender(Job)) { Console.WriteLine("render failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        Console.WriteLine("rendered " + LumasPdf.rptGetPageCount(Job) + " page(s) from the custom provider");
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf);
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt);
        Console.WriteLine("wrote " + OutPdf + "  +  " + OutTxt);
        LumasPdf.rptCloseReport(Job);
    Cleanup:
        LumasPdf.rptDeleteEngine(mEng);
        LumasPdf.pdfDeletePDF(mPdf);
    }
}
