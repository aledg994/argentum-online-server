Attribute VB_Name = "AIv2"
Option Explicit

Public Sub IrUsuarioCercano(ByVal NpcIndex As Integer)
    On Error GoTo ErrorHandler
  
    Dim UserIndex As Integer
    Dim i         As Long
    Dim minDistancia As Integer

    ' Numero muy grande para que siempre haya un mínimo
    minDistancia = 32000
    
    With NpcList(NpcIndex)

        For i = 1 To ModAreas.ConnGroups(.Pos.Map).CountEntrys
            UserIndex = ModAreas.ConnGroups(.Pos.Map).UserEntrys(i)
                    
            If EsObjetivoValido(NpcIndex, UserIndex) Then
            
                If Distancia(UserList(UserIndex).Pos, .Pos) < minDistancia Then
                    .Target = UserIndex
                    minDistancia = Distancia(UserList(UserIndex).Pos, .Pos)
                End If
                
            End If
             
        Next i

        If .Target > 0 Then
        
            If EnRangoVision(NpcIndex, .Target, .Pos.X, .Pos.Y) Then
                Call AI_AtacarObjetivo(NpcIndex)
            Else
                ' El usuario se alejo demasiado.
                .Target = 0
            End If
       
        End If

    End With
    
    Exit Sub
    
ErrorHandler:
    Call RegistrarError(Err.Number, Err.Description, "AIv2.IrUsuarioCercano", Erl)
    
End Sub

Private Sub AI_AtacarObjetivo(ByVal AtackerNpcIndex As Integer)

    On Error GoTo ErrorHandler

    Dim PegoConMagia        As Boolean
    Dim EstaLejosDelUsuario As Boolean
    Dim tHeading As Byte
    
    With NpcList(AtackerNpcIndex)
        
        If .Target = 0 Then Exit Sub
        
        EstaLejosDelUsuario = (Distancia(.Pos, UserList(.Target).Pos) > 1)
        PegoConMagia = (.flags.LanzaSpells And (RandomNumber(1, 2) = 1 Or .flags.Inmovilizado Or EstaLejosDelUsuario))

        If PegoConMagia Then
        
            ' Le lanzo un Hechizo
            Call NpcLanzaUnSpell(AtackerNpcIndex, .Target)
                
        ElseIf EstaLejosDelUsuario Then
        
            ' Camino hacia el Usuario
            tHeading = FindDirectionEAO(.Pos, UserList(.Target).Pos, .flags.AguaValida = 1, .flags.TierraInvalida = 0)
            Call MoveNPCChar(AtackerNpcIndex, tHeading)
                
        Else
            
            ' Se da vuelta y enfrenta al Usuario
            tHeading = FindDirectionEAO(.Pos, UserList(.Target).Pos, .flags.AguaValida = 1, .flags.TierraInvalida = 0)
            Call AnimacionIdle(AtackerNpcIndex, True)
            Call ChangeNPCChar(AtackerNpcIndex, .Char.Body, .Char.Head, tHeading)
            
            ' Le pego al Usuario
            Call NpcAtacaUser(AtackerNpcIndex, .Target, tHeading)
                
        End If
        
    End With
    
    Exit Sub
    
ErrorHandler:
    
    Call RegistrarError(Err.Number, Err.Description, "AIv2.AI_AtacarObjetivo", Erl)
    
End Sub

Public Sub SeguirAgresor(ByVal NpcIndex As Integer)
    
    ' La IA que se ejecuta cuando alguien le pega al maestro de una Mascota/Elemental
    
    With NpcList(NpcIndex)
        
        If EsObjetivoValido(NpcIndex, .Target, False) Then
        
            Call AI_AtacarObjetivo(NpcIndex)
        
        Else
        
            Call RestoreOldMovement(NpcIndex)
        
        End If
        
    End With
    
End Sub

Private Sub RestoreOldMovement(ByVal NpcIndex As Integer)

    With NpcList(NpcIndex)
        
        ' Si el NPC no tiene maestro, reseteamos el movimiento que tenia antes.
        If .MaestroUser = 0 Then
        
            .Movement = .flags.OldMovement
            .Hostile = .flags.OldHostil
            .flags.AttackedBy = vbNullString
            .Target = 0
            
        Else
            
            ' Si tiene maestro, hacemos que lo siga.
            Call FollowAmo(NpcIndex)
            
        End If

    End With

End Sub

' ---------------------------------------------------------------------------------------------------
'                                       HELPERS
' ---------------------------------------------------------------------------------------------------

Private Function UsuarioEnVistaPerisfericaDelNPC(ByVal UserIndex As Integer, _
                                                 ByVal NpcIndex As Integer) As Boolean
    
    Dim UserPos As WorldPos
        UserPos = UserList(UserIndex).Pos
    
    With NpcList(NpcIndex)
    
        Select Case .Char.Heading

            Case eHeading.NORTH
                UsuarioEnVistaPerisfericaDelNPC = (.Pos.Y > UserPos.Y)
           
            Case eHeading.EAST
                UsuarioEnVistaPerisfericaDelNPC = (.Pos.X > UserPos.X)

            Case eHeading.SOUTH
                UsuarioEnVistaPerisfericaDelNPC = (.Pos.Y < UserPos.Y)
                
            Case eHeading.WEST
                UsuarioEnVistaPerisfericaDelNPC = (.Pos.X < UserPos.X)
                
        End Select
    
    End With

End Function

Private Function EsObjetivoValido(ByVal NpcIndex As Integer, ByVal UserIndex As Integer, Optional ByVal RespetarHeading As Boolean = False) As Boolean
    
    ' Esto se ejecuta cuando el NPC NO tiene ningun objetivo en primer lugar.
    
    Dim RangoX    As Byte
    Dim RangoY    As Byte
        
    With NpcList(NpcIndex)
        
        RangoX = IIf(.Distancia <> 0, .Distancia, RANGO_VISION_X)
        RangoY = IIf(.Distancia <> 0, .Distancia, RANGO_VISION_Y)
        
    End With
    
    If UserIndex > 0 Then
    
        EsObjetivoValido = (EnRangoVision(NpcIndex, UserIndex, RangoX, RangoY) And PuedeAtacarUser(UserIndex))
        
        If RespetarHeading Then
        
            EsObjetivoValido = EsObjetivoValido And UsuarioEnVistaPerisfericaDelNPC(UserIndex, NpcIndex)
            
        End If
        
    Else
        
        EsObjetivoValido = False
    
    End If
    
End Function

Private Function EnRangoVision(ByVal NpcIndex As Integer, ByVal UserIndex As Integer, ByVal Limite_X As Byte, ByVal Limite_Y As Integer) As Boolean
    
    EnRangoVision = (Abs(UserList(UserIndex).Pos.X - NpcList(NpcIndex).Pos.X) <= Limite_X And Abs(UserList(UserIndex).Pos.Y - NpcList(NpcIndex).Pos.Y) <= Limite_Y)

End Function

Private Function PuedeAtacarUser(ByVal targetUserIndex As Integer) As Boolean
    
    With UserList(targetUserIndex)
            
        PuedeAtacarUser = (.flags.Muerto = 0 And .flags.invisible = 0 And .flags.Inmunidad = 0 And .flags.Oculto = 0 And .flags.Mimetizado < e_EstadoMimetismo.FormaBichoSinProteccion And Not EsGM(targetUserIndex) And Not .flags.EnConsulta)
                                
    End With

End Function