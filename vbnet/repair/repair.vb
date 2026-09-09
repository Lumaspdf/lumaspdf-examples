' repair -- fix a damaged PDF with a SINGLE method: pdfConvertFileA(ctNormalize).
' VB.NET port of examples\c\repair\repair.c
Imports System
Imports LumasPdfSdk

Module Repair
    Function Main() As Integer
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()

        Dim rc As Integer = LumasPdf.pdfConvertFileW(pdf, _
            "../../test_files/corrupt.pdf", _
            "repaired.pdf", _
            CInt(TConformanceType.ctNormalize), 0UI, _
            Nothing, Nothing, Nothing, IntPtr.Zero, Nothing, Nothing)

        ' Native GetInRepairMode is a LongBool (-1 when true); mirror the C (int) cast.
        Dim mode As Integer = If(LumasPdf.pdfGetInRepairMode(pdf), -1, 0)
        Console.WriteLine("pdfConvertFile(ctNormalize) rc=" & rc & _
            "  (repair-mode used: " & mode & ")")

        LumasPdf.pdfDeletePDF(pdf)
        Return If(rc < 0, 1, 0)
    End Function
End Module
