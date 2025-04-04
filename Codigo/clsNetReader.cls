VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsNetReader"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'    Argentum 20 - Game Client Program
'    Copyright (C) 2025 - Noland Studios
'
'    This program is free software: you can redistribute it and/or modify
'    it under the terms of the GNU Affero General Public License as published by
'    the Free Software Foundation, either version 3 of the License, or
'    (at your option) any later version.
'
'    This program is distributed in the hope that it will be useful,
'    but WITHOUT ANY WARRANTY; without even the implied warranty of
'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'    GNU Affero General Public License for more details.
'    You should have received a copy of the GNU Affero General Public License
'    along with this program.  If not, see <https://www.gnu.org/licenses/>.

#If DIRECT_PLAY = 1 Then

Option Base 0

Option Explicit

Private rcv_data As DxVBLibA.DPNMSG_RECEIVE
Private loffset As Long
Public Function GetAvailable() As Integer
    GetAvailable = rcv_data.lDataSize - loffset
End Function
Public Sub set_data(data As DxVBLibA.DPNMSG_RECEIVE)
    rcv_data = data
    loffset = 0
End Sub

Public Sub Clear()
    lOffset = NewBuffer(rcv_data.ReceivedData)
End Sub
Public Function ReadInt16() As Integer
    Call GetDataFromBuffer(rcv_data.ReceivedData, ReadInt16, SIZE_INTEGER, loffset)
End Function
Public Function ReadInt32() As Long
    Call GetDataFromBuffer(rcv_data.ReceivedData, ReadInt32, SIZE_LONG, lOffset)
End Function
Public Function ReadBool() As Boolean
    Call GetDataFromBuffer(rcv_data.ReceivedData, ReadBool, SIZE_BOOLEAN, lOffset)
End Function
Public Function ReadReal32() As Single
    Call GetDataFromBuffer(rcv_data.ReceivedData, ReadReal32, SIZE_SINGLE, lOffset)
End Function
Public Function ReadInt8() As Byte
    Call GetDataFromBuffer(rcv_data.ReceivedData, ReadInt8, SIZE_BYTE, loffset)
End Function
Public Function ReadString8() As String
    ReadString8 = GetStringFromBuffer(rcv_data.ReceivedData, loffset)
End Function

Public Function ReadSafeArrayInt8(value() As Byte)
    Dim lower_b As Integer
    Dim upper_b As Integer
    lower_b = ReadInt32
    upper_b = ReadInt32
    Dim i As Integer
    ReDim value(lower_b To upper_b)
    For i = lower_b To upper_b
        value(i) = ReadInt8
    Next i
End Function

#End If
