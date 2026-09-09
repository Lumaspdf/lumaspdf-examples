' layer_tree -- VB.NET port of examples\Vb6\layers\layer_tree
Imports System
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modLayerTree
    Private ErrDel As TErrorProc
    Private Const clBlue As UInteger = &HFF0000UI
    Private Const clBlack As UInteger = &H0UI

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        ErrDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, CInt(TPageCoord.pcTopDown))
        LumasPdf.pdfSetUseTransparency(pdf, False)

        Dim oc1 As Integer = LumasPdf.pdfCreateOCGW(pdf, "All", False, True, CUInt(LumasPdfConsts.oiAll))
        Dim oc2 As Integer = LumasPdf.pdfCreateOCGW(pdf, "Text and Annotations", False, True, CUInt(LumasPdfConsts.oiAll))
        Dim oc3 As Integer = LumasPdf.pdfCreateOCGW(pdf, "Images", False, True, CUInt(LumasPdfConsts.oiAll))

        Dim root As IntPtr = LumasPdf.pdfAddLayerToDisplTreeW(pdf, IntPtr.Zero, oc1, "A layer group with a title")
        Dim grp As IntPtr = LumasPdf.pdfAddLayerToDisplTreeW(pdf, root, -1, "")
        LumasPdf.pdfAddLayerToDisplTreeW(pdf, grp, oc2, "")
        LumasPdf.pdfAddLayerToDisplTreeW(pdf, grp, oc3, "")

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfBeginLayer(pdf, CUInt(oc1))
        LumasPdf.pdfBeginLayer(pdf, CUInt(oc2))
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 12.0, False, TCodepage.cp1252)
        Dim someText As String = "Some text with a link!!!"
        LumasPdf.pdfSetFillColor(pdf, clBlue)
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, someText)
        Dim tw As Double = LumasPdf.pdfGetTextWidthW(pdf, someText)
        LumasPdf.pdfSetBorderStyle(pdf, CInt(TBorderStyle.bsUnderline))
        LumasPdf.pdfSetStrokeColor(pdf, clBlue)
        Dim annot As Integer = LumasPdf.pdfWebLinkW(pdf, 50.0, 51.0, tw, 12.0, "www.dynaforms.com")

        ' pdfCreateOCMD's OCGs parameter is a typed UInteger() in the binding
        ' (matching the C# side), so the marshaller pins and passes the array.
        ' This used to hand-pin with GCHandle and pass AddrOfPinnedObject()
        ' because the VB generator flattened every array parameter to IntPtr --
        ' a divergence from the C# binding that has since been fixed in
        ' tools/gen_vb.py. Same native call, same output, less ceremony.
        Dim ocArray() As UInteger = {CUInt(oc1), CUInt(oc2)}
        Dim ocmd As Integer = LumasPdf.pdfCreateOCMD(pdf, TOCVisibility.ovAllOn, ocArray, 2)
        LumasPdf.pdfAddObjectToLayer(pdf, CUInt(ocmd), TOCObject.ooAnnotation, CUInt(annot))
        LumasPdf.pdfEndLayer(pdf)

        LumasPdf.pdfBeginLayer(pdf, CUInt(oc3))
        LumasPdf.pdfInsertImageExW(pdf, 50.0, 70.0, 300.0, 200.0, "../../../test_files/images/margarita-102572_640.jpg", 1)
        LumasPdf.pdfEndLayer(pdf)
        LumasPdf.pdfEndLayer(pdf)

        LumasPdf.pdfSetFillColor(pdf, clBlack)
        LumasPdf.pdfWriteTextW(pdf, 50.0, 300.0, "This text is not part of a layer!")
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfSetPageMode(pdf, CInt(TPageMode.pmUseOC))

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            Dim outFile As String = AppPath() & "\out.pdf"
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            If LumasPdf.pdfCloseFile(pdf) <> 0 Then
                Console.WriteLine("PDF file """ & outFile & """ successfully created!")
            End If
        End If
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
