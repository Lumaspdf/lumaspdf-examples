Attribute VB_Name = "modPrintPdf"
Option Explicit
' ============================================================================
'  print_pdf -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Loads a PDF, imports the first page and prints it. A printer is chosen
'  through the standard Print dialog (PrintDlg), exactly as the Delphi original.
'  Compile-only in headless CI (needs a printer + interactive dialog).
' ============================================================================

Private Type PRINTDLG
    lStructSize As Long
    hwndOwner As Long
    hDevMode As Long
    hDevNames As Long
    hDC As Long
    Flags As Long
    nFromPage As Integer
    nToPage As Integer
    nMinPage As Integer
    nMaxPage As Integer
    nCopies As Integer
    hInstance As Long
    lCustData As Long
    lpfnPrintHook As Long
    lpfnSetupHook As Long
    lpPrintTemplateName As Long
    lpSetupTemplateName As Long
    hPrintTemplate As Long
    hSetupTemplate As Long
End Type

Private Declare Function PrintDlg Lib "comdlg32.dll" Alias "PrintDlgA" (ByRef pPD As PRINTDLG) As Long
Private Declare Function DeleteDC Lib "gdi32" (ByVal hDC As Long) As Long

Private Const PD_RETURNDC As Long = &H100
Private Const PD_HIDEPRINTTOFILE As Long = &H100000
Private Const PD_DISABLEPRINTTOFILE As Long = &H80000
Private Const PD_NOSELECTION As Long = &H4

Private Function GetPrinterDC() As Long
    Dim pd As PRINTDLG
    pd.lStructSize = Len(pd)
    pd.Flags = PD_RETURNDC Or PD_HIDEPRINTTOFILE Or PD_DISABLEPRINTTOFILE Or PD_NOSELECTION
    If PrintDlg(pd) <> 0 Then
        GetPrinterDC = pd.hDC
    Else
        Debug.Print "Cancelled!"
        GetPrinterDC = 0
    End If
End Function

Public Sub Main()
    ' NOTE: PrintPDFFileA takes the printer HDC as a 64-bit handle (__int64 in the
    ' type library). VB6 cannot early-bind a method with an Automation I8 param
    ' ("type not supported in Visual Basic"), so this one object is late-bound
    ' (still the registered AX server, still zero wrapper modules); the enum
    ' constants below continue to come from the referenced type library.
    Dim pdf As Object
    Dim dc As Long
    Set pdf = New CPDF
' pdf.RaiseExceptions = True

    pdf.CreateNewPDF ""   ' We create no PDF file in this example

    ' Import anything and don't convert pages to templates
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    If pdf.OpenImportFile(App.Path & "\..\..\..\..\dynapdf_help.pdf", ptOpen, "") < 0 Then Exit Sub

    ' We print only the first page in this example.
    pdf.Append
    pdf.ImportPageEx 1, 1#, 1#
    pdf.EndPage

    ' ApplyAppEvent makes sure the same result is printed that Acrobat would print (layers, etc.).
    pdf.ApplyAppEvent aePrint, 0

    dc = GetPrinterDC()
    If dc <> 0 Then
        If pdf.PrintPDFFileA("", "Test Print", dc, pffDefault Or pffAutoRotateAndCenter Or pffShrinkToPrintArea, 0, 0) <> 0 Then
            Debug.Print "Page 1 successfully printed"
        End If
        DeleteDC dc
    End If
End Sub
