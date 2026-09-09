' field_groups -- VB.NET port of examples\Vb6\acroform\field_groups
Imports System
Imports System.IO
Imports LumasPdfSdk

Module FieldGroups
    Private Const clLtGray As UInteger = 12632256UI
    Private errDel As TErrorProc

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Return 0
    End Function

    Sub Main()
        Dim act As Integer, f As Integer
        Dim base As Double, y As Double
        Dim cr As String = vbCr
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 12.0, False, TCodepage.cp1252)
        LumasPdf.pdfSetLeading(pdf, 14.0)
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 50.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, -1.0, LumasPdfConsts.taJustify, _
            "The six text fields share the same value. Such an array of fields is called a field group. All fields in the group must be of the same type." & cr & cr & _
            "A field group can be created in two different ways: either create two or more fields with the same name or pass the handle of the base field as Parent to the children. " & _
            "The latter way is more efficient since it is not required to search for the parent field when a child will be created." & cr & cr & _
            "Enter some more text into a field to see the difference between auto size and fixed font size.")

        base = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 20.0

        LumasPdf.pdfWriteFTextExW(pdf, 50.0, base, 200.0, -1.0, LumasPdfConsts.taLeft, "Font size <= 1.0 means auto size.")

        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0

        LumasPdf.pdfChangeFontSize(pdf, 1.0)
        f = LumasPdf.pdfCreateTextField(pdf, "Auto", -1, 0, 0, 50.0, y, 200.0, 20.0)
        LumasPdf.pdfSetTextFieldValueW(pdf, f, "Some text...", "Some text...", LumasPdfConsts.taLeft)

        y = y + 30.0
        LumasPdf.pdfCreateTextField(pdf, "", f, 0, 0, 50.0, y, 200.0, 30.0)

        y = y + 40.0
        LumasPdf.pdfCreateTextField(pdf, "", f, 0, 0, 50.0, y, 200.0, 40.0)

        LumasPdf.pdfChangeFontSize(pdf, 12.0)
        LumasPdf.pdfWriteFTextExW(pdf, 345.0, base, 200.0, -1.0, LumasPdfConsts.taLeft, "The same fields with a fixed font size.")

        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0

        LumasPdf.pdfChangeFontSize(pdf, 12.0)
        LumasPdf.pdfCreateTextField(pdf, "", f, 0, 0, 345.0, y, 200.0, 20.0)

        y = y + 30.0
        LumasPdf.pdfChangeFontSize(pdf, 24.0)
        LumasPdf.pdfCreateTextField(pdf, "", f, 0, 0, 345.0, y, 200.0, 30.0)

        y = y + 40.0
        LumasPdf.pdfChangeFontSize(pdf, 34.0)
        LumasPdf.pdfCreateTextField(pdf, "", f, 0, 0, 345.0, y, 200.0, 40.0)

        LumasPdf.pdfChangeFontSize(pdf, 18.0)
        f = LumasPdf.pdfCreateButtonW(pdf, "Reset", "Reset", -1, 222.5, y + 80.0, 150.0, 25.0)
        LumasPdf.pdfSetFieldColor(pdf, f, TFieldColor.fcBackColor, TPDFColorSpace.csDeviceRGB, clLtGray)
        LumasPdf.pdfSetFieldBorderStyle(pdf, f, TBorderStyle.bsBevelled)

        act = LumasPdf.pdfCreateResetAction(pdf)
        LumasPdf.pdfAddActionToObj(pdf, TObjType.otField, TObjEvent.oeOnMouseUp, act, f)
        LumasPdf.pdfEndPage(pdf)

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            Dim outFile As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf")
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
