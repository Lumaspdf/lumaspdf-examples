' print_pdf -- VB.NET port of examples\Vb6\rendering_engine\print_pdf
' COMPILE ONLY: opens the Windows print dialog at runtime.
Imports System
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modPrintPdf
    Private errDel As TErrorProc

    <StructLayout(LayoutKind.Sequential)>
    Private Structure PRINTDLG
        Public lStructSize As Integer
        Public hwndOwner As IntPtr
        Public hDevMode As IntPtr
        Public hDevNames As IntPtr
        Public hDC As IntPtr
        Public Flags As Integer
        Public nFromPage As UShort
        Public nToPage As UShort
        Public nMinPage As UShort
        Public nMaxPage As UShort
        Public nCopies As UShort
        Public hInstance As IntPtr
        Public lCustData As IntPtr
        Public lpfnPrintHook As IntPtr
        Public lpfnSetupHook As IntPtr
        Public lpPrintTemplateName As IntPtr
        Public lpSetupTemplateName As IntPtr
        Public hPrintTemplate As IntPtr
        Public hSetupTemplate As IntPtr
    End Structure

    <DllImport("comdlg32.dll", EntryPoint:="PrintDlgA", CharSet:=CharSet.Ansi, SetLastError:=True)>
    Private Function ShowPrintDlg(ByRef pPD As PRINTDLG) As Boolean
    End Function

    <DllImport("gdi32.dll")>
    Private Function DeleteDC(ByVal hDC As IntPtr) As Boolean
    End Function

    Private Const PD_RETURNDC As Integer = &H100
    Private Const PD_HIDEPRINTTOFILE As Integer = &H100000
    Private Const PD_DISABLEPRINTTOFILE As Integer = &H80000
    Private Const PD_NOSELECTION As Integer = &H4

    Private Function U(ByVal v As Long) As UInteger
        Return CUInt(v And &HFFFFFFFFL)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Private Function GetPrinterDC() As IntPtr
        Dim pd As New PRINTDLG
        pd.lStructSize = Marshal.SizeOf(GetType(PRINTDLG))
        pd.Flags = PD_RETURNDC Or PD_HIDEPRINTTOFILE Or PD_DISABLEPRINTTOFILE Or PD_NOSELECTION
        If ShowPrintDlg(pd) Then
            Return pd.hDC
        Else
            Console.WriteLine("Cancelled!")
            Return IntPtr.Zero
        End If
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetImportFlags(pdf, U(LumasPdfConsts.ifImportAll Or LumasPdfConsts.ifImportAsPage))
        If LumasPdf.pdfOpenImportFileW(pdf, "../../../../sample_multipage.pdf", LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfImportPageEx(pdf, 1, 1.0, 1.0)
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfApplyAppEvent(pdf, U(LumasPdfConsts.aePrint), False)

        Dim dc As IntPtr = GetPrinterDC()
        If dc <> IntPtr.Zero Then
            If LumasPdf.pdfPrintPDFFileW(pdf, "", "Test Print", New UIntPtr(CULng(dc.ToInt64())), _
                U(LumasPdfConsts.pffDefault Or LumasPdfConsts.pffAutoRotateAndCenter Or LumasPdfConsts.pffShrinkToPrintArea), _
                IntPtr.Zero, IntPtr.Zero) Then
                Console.WriteLine("Page 1 successfully printed")
            End If
            DeleteDC(dc)
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
