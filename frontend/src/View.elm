module View exposing (..)

import Model exposing (..)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, href, target, src, colspan, title)
import Html.Events exposing (onClick, onWithOptions)
import Components exposing (..)
import Utils exposing (..)
import Json.Decode as JD


notification : Notification -> Html Msg
notification notification =
    let
        ( txt, messageClass ) =
            case notification.notification of
                Success str ->
                    ( str, "is-success" )

                Warning str ->
                    ( str, "is-warning" )

                Error str ->
                    ( str, "is-danger" )
    in
        div [ class ("notification on " ++ messageClass) ]
            [ button
                [ class "delete"
                , onClick (DeleteNotification notification.id)
                ]
                []
            , text txt
            ]


notificationsView : Model -> Html Msg
notificationsView model =
    div [ class "toast" ] (model.notifications |> List.map notification)


nodeModal : Model -> Html Msg
nodeModal model =
    let
        node =
            model.nodeForm

        ( submitButton, cancelButton ) =
            ( Just ( "Submit", SubmitNode )
            , Just ( "Cancel", ToggleNodeModal Nothing )
            )

        modalTitle =
            if node.isNew then
                "Create a New Node"
            else
                "Editing Node"
    in
        modalCard model.isLoading
            modalTitle
            (ToggleNodeModal Nothing)
            [ form []
                [ columns False
                    [ fieldInput
                        model.isLoading
                        "Account"
                        node.account
                        "cypherglass1"
                        "user"
                        UpdateNodeFormAccount
                        (not node.isNew)
                    , text ""
                    ]
                , columns False
                    [ fieldInput
                        model.isLoading
                        "IP"
                        node.ip
                        "127.0.0.1"
                        "server"
                        UpdateNodeFormIp
                        False
                    , fieldInput
                        model.isLoading
                        "Port"
                        (toString node.addrPort)
                        "8888"
                        "lock"
                        UpdateNodeFormPort
                        False
                    ]
                , columns False
                    [ checkBoxInput
                        model.isLoading
                        "SSL"
                        "Above Address is HTTPS"
                        node.isSsl
                        UpdateNodeFormIsSsl
                        False
                    , checkBoxInput
                        model.isLoading
                        "Alerts"
                        "Watch and Receive Alerts"
                        node.isWatchable
                        UpdateNodeFormIsWatchable
                        False
                    ]
                , columns False
                    [ selectInput
                        model.isLoading
                        [ ( "BP", "BP - Block Producer" )
                        , ( "FN", "FN - Full Node" )
                        , ( "EBP", "EBP - External Nodes / Block Producers" )
                        ]
                        "Node Type"
                        (nodeTypeTxt node.nodeType)
                        "globe"
                        UpdateNodeFormType
                    , fieldInput
                        model.isLoading
                        "Dashboard Position Order"
                        (toString node.position)
                        "1"
                        "trophy"
                        UpdateNodeFormPosition
                        False
                    ]
                ]
            ]
            submitButton
            cancelButton


nodeChainInfoModal : Model -> Html Msg
nodeChainInfoModal model =
    let
        ( modalTitle, content ) =
            case model.viewingNode of
                Just node ->
                    ( "Node " ++ node.account ++ " Chain Info"
                    , case model.chainInfo of
                        Just chainInfo ->
                            [ columns False
                                [ displayField
                                    "Account"
                                    node.account
                                    ""
                                , displayField
                                    "Server Version"
                                    chainInfo.serverVersion
                                    ""
                                ]
                            , columns False
                                [ displayField
                                    "Head Block Number"
                                    (toString chainInfo.headBlockNum)
                                    ""
                                , displayField
                                    "Head Block Time"
                                    (formatTime chainInfo.headBlockTime)
                                    ""
                                , displayField
                                    "Last Irrev. Block Num"
                                    (toString chainInfo.lastIrreversibleBlockNum)
                                    ""
                                ]
                            , displayField
                                "Head Block Id"
                                chainInfo.headBlockId
                                ""
                            , displayField
                                "Last Irreversible Block Id"
                                chainInfo.lastIrreversibleBlockId
                                ""
                            , displayField
                                "Chain Id"
                                chainInfo.chainId
                                ""
                            ]

                        Nothing ->
                            [ text "Loading Chain Info" ]
                    )

                Nothing ->
                    ( "Loading Node Chain Info", [ text "Loading Node" ] )
    in
        modalCard model.isLoading
            modalTitle
            (ToggleNodeChainInfoModal Nothing)
            [ form [] content ]
            Nothing
            Nothing


adminLoginModal : Model -> Html Msg
adminLoginModal model =
    let
        ( submitButton, cancelButton ) =
            ( Just ( "Submit", SubmitAdminLogin )
            , Just ( "Cancel", ToggleAdminLoginModal )
            )
    in
        modalCard model.isLoading
            "System Admin Login"
            (ToggleNodeModal Nothing)
            [ form
                [ onWithOptions "submit"
                    { preventDefault = True, stopPropagation = False }
                    (JD.succeed SubmitAdminLogin)
                ]
                [ passwordInput
                    model.isLoading
                    "System Admin Password"
                    model.adminPassword
                    "password"
                    "lock"
                    UpdateAdminLoginPassword
                    False
                ]
            ]
            submitButton
            cancelButton


helpModal : Model -> Html Msg
helpModal model =
    modalCard model.isLoading
        "Cypherglass WINDSHIELD - Help/About"
        ToggleHelp
        [ div [ class "content" ]
            [ p [] [ text "Cypherglass WINDSHIELD is a smart tracker EOS nodes: active block producers, full nodes and external nodes of the EOS chain." ]
            , h3 [] [ text "Nodes Types:" ]
            , ul []
                [ li []
                    [ nodeTagger BlockProducer
                    , b [] [ text " - " ]
                    , text "This is your main EOS Block Producer, you will set this one as the principal node. It's used to query the head block number as  a comparison base to other nodes. WINDSHIELD will automatically alert you of the voting rank of this BP node."
                    ]
                , li []
                    [ nodeTagger FullNode
                    , b [] [ text " - " ]
                    , text "These are full nodes that are usually published to the world. WINDSHIELD automatically checks to see if they are healthy and synced to your principal Block Producer node."
                    ]
                , li []
                    [ nodeTagger ExternalBlockProducer
                    , b [] [ text " - " ]
                    , text "These are external Key Nodes that WINDSHIELD keeps track of, so you can see if your BlockProducer is aligned with them or if it has been forked. WINDSHIELD need to always be updated with the top 21 block producer public nodes.  WINDSHIELD alerts you if new producers have ascended to voting rank."
                    ]
                ]
            ]
        ]
        Nothing
        Nothing


archiveConfirmationModal : Model -> Html Msg
archiveConfirmationModal model =
    case model.viewingNode of
        Just node ->
            modalCard model.isLoading
                ("Archive Node " ++ node.account)
                CancelArchive
                [ div [ class "content" ]
                    [ p [] [ text ("Are you sure that you want to archive the node " ++ node.account ++ "?") ]
                    ]
                ]
                (Just ( "Yes, I Want to Archive " ++ node.account, SubmitArchive node ))
                (Just ( "Cancel", CancelArchive ))

        _ ->
            text ""


restoreConfirmationModal : Model -> Html Msg
restoreConfirmationModal model =
    case model.viewingNode of
        Just node ->
            modalCard model.isLoading
                ("Restore Node " ++ node.account)
                CancelRestore
                [ div [ class "content" ]
                    [ p [] [ text ("Are you sure that you want to restore the node " ++ node.account ++ "?") ]
                    ]
                ]
                (Just ( "Yes, I Want to Restore " ++ node.account, SubmitRestore node ))
                (Just ( "Cancel", CancelRestore ))

        _ ->
            text ""


topMenu : Model -> Html Msg
topMenu model =
    let
        logButton =
            if not (String.isEmpty model.user.token) then
                a
                    [ class "navbar-item"
                    , onClick Logout
                    ]
                    [ span [ class "navbar-item icon is-small" ]
                        [ i [ class "fa fa-2x fa-unlock has-text-danger" ] [] ]
                    ]
            else
                a
                    [ class "navbar-item"
                    , onClick ToggleAdminLoginModal
                    ]
                    [ span [ class "navbar-item icon is-small" ]
                        [ i [ class "fa fa-2x fa-lock has-text-primary" ] [] ]
                    ]

        ( isActiveMonitorClass, isActiveAlertsClass, isActiveSettingsClass ) =
            case model.content of
                Home ->
                    ( "is-active", "", "" )

                Alerts ->
                    ( "", "is-active", "" )

                SettingsView ->
                    ( "", "", "is-active" )

        helpButton =
            a
                [ class "navbar-item"
                , onClick ToggleHelp
                ]
                [ span [ class "navbar-item icon is-small" ]
                    [ i [ class "fa fa-2x fa-question-circle has-text-info" ] [] ]
                ]

        monitorButton =
            a [ class ("navbar-item " ++ isActiveMonitorClass), onClick (SetContent Home) ]
                [ icon "dashboard" False False
                , span [ class "navbar-item-text" ] [ text "Dashboard" ]
                ]

        alertsButton =
            a [ class ("navbar-item " ++ isActiveAlertsClass), onClick (SetContent Alerts) ]
                [ icon "bell" False False
                , span [ class "navbar-item-text" ] [ text "Alerts" ]
                ]

        settingsButton =
            a [ class ("navbar-item " ++ isActiveSettingsClass), onClick (SetContent SettingsView) ]
                [ icon "cog" False False
                , span [ class "navbar-item-text" ] [ text "Settings" ]
                ]

        soundIcon =
            "fa fa-2x "
                ++ if model.isMuted then
                    "fa-volume-off has-text-danger"
                   else
                    "fa-volume-up has-text-success"

        soundButton =
            a
                [ class "navbar-item"
                , onClick ToggleSound
                ]
                [ span [ class "navbar-item icon is-small" ]
                    [ i [ class soundIcon ] [] ]
                ]

        content =
            [ p [ class "navbar-item" ] [ loadingIcon model.isLoading ]
            , monitorButton
            , alertsButton
            , settingsButton
            , soundButton
            , helpButton
            , logButton
            ]

        monitorStatus =
            model.monitorState.status

        monitorConnectionStatus =
            if
                model.monitorConnected
                    && (monitorStatus == Active || monitorStatus == Syncing)
            then
                p [ class "has-text-success" ] [ text "Online" ]
            else if model.monitorConnected && monitorStatus == InitialMonitor then
                p [ class "has-text-warning" ] [ text "Pending Initialization" ]
            else
                p [ class "has-text-danger" ] [ text "OFFLINE" ]

        currentProducer =
            case model.currentProducer of
                Just acc ->
                    acc

                Nothing ->
                    "--"
    in
        nav
            [ attribute "aria-label" "main navigation"
            , class "navbar topcg"
            , attribute "role" "navigation"
            ]
            [ div [ class "navbar-brand logo" ]
                [ img [ class "logo-img", src "/logo_horizontal.svg" ] []
                , span [ class "title-span is-hidden-mobile" ] [ text "WINDSHIELD" ]
                , span [ class "title-span is-hidden-tablet" ] [ text "WS" ]
                , div [ class "monitor-stats is-hidden-mobile" ]
                    [ monitorConnectionStatus
                    , p [] [ text ("Last Sync.Block: " ++ toString model.monitorState.lastBlockNum) ]
                    , p [ class "has-text-warning" ]
                        [ text "Current Prod: "
                        , b [] [ text currentProducer ]
                        ]
                    ]
                ]
            , div [ class "navbar-menu" ]
                [ div [ class "navbar-end" ]
                    content
                ]
            ]


mainContent : Model -> Html Msg
mainContent model =
    let
        defaultContent content =
            section [ class "section" ]
                [ div [ class "container" ]
                    [ content
                    ]
                ]
    in
        case model.content of
            Home ->
                defaultContent (monitorContent model)

            Alerts ->
                defaultContent (alertsContent model)

            SettingsView ->
                defaultContent (settingsContent model)


alertsContent : Model -> Html Msg
alertsContent model =
    let
        alertRow insideModel alert =
            tr []
                [ td [] [ text alert.alertType ]
                , td [] [ text (calcTimeDiff alert.createdAt insideModel.currentTime) ]
                , td [] [ text alert.description ]
                ]

        alertsRows =
            if List.length model.alerts > 0 then
                model.alerts
                    |> List.take 30
                    |> List.map (\a -> alertRow model a)
            else
                [ tr []
                    [ td [ colspan 3 ] [ text "Yayyy! No alerts!" ]
                    ]
                ]
    in
        div [ class "content" ]
            [ h2 [] [ text "Most Recent Alerts" ]
            , table [ class "table is-striped is-hoverable is-fullwidth" ]
                [ thead []
                    (tr []
                        [ th [] [ text "Type" ]
                        , th [] [ text "When" ]
                        , th [] [ text "Description" ]
                        ]
                        :: alertsRows
                    )
                ]
            ]


monitorContent : Model -> Html Msg
monitorContent model =
    let
        menu =
            if not (String.isEmpty model.user.token) then
                if model.showArchivedNodes then
                    [ a [ onClick ToggleArchivedNodes ] [ text "Active Nodes" ] ]
                else
                    [ a [ onClick ToggleArchivedNodes ] [ text "Archived Nodes" ]
                    , a
                        [ class "button is-success"
                        , onClick (ToggleNodeModal (Just newNode))
                        ]
                        [ text "Add Node" ]
                    ]
            else
                [ text "" ]

        contentTitle =
            if model.showArchivedNodes then
                "Archived Nodes"
            else
                "Nodes Dashboard"

        list =
            if model.showArchivedNodes then
                archivedNodesList model
            else
                nodesList model
    in
        div [ class "content" ]
            [ titleMenu contentTitle menu
            , list
            ]


nodeTagger : NodeType -> Html Msg
nodeTagger nodeType =
    let
        ( txt, nodeClass ) =
            case nodeType of
                BlockProducer ->
                    ( "BlockPrd", "is-success" )

                FullNode ->
                    ( "FullNode", "is-info" )

                ExternalBlockProducer ->
                    ( "External", "is-light" )
    in
        span [ class ("tag " ++ nodeClass) ] [ text txt ]


nodesComparison : Node -> Node -> Order
nodesComparison a b =
    case compare a.position b.position of
        LT ->
            LT

        EQ ->
            case compare a.votePosition b.votePosition of
                LT ->
                    LT

                EQ ->
                    compare a.account b.account

                GT ->
                    GT

        GT ->
            GT


nodesList : Model -> Html Msg
nodesList model =
    let
        nodes =
            model.nodes

        nodesRows =
            if List.length nodes > 0 then
                nodes
                    |> List.filter (\n -> not n.isArchived)
                    |> List.sortWith nodesComparison
                    |> List.map (\n -> nodeRow model n)
            else
                [ tr []
                    [ td
                        [ colspan 9
                        , class "has-text-centered"
                        ]
                        [ text "Nodes not loaded" ]
                    ]
                ]
    in
        table [ class "table is-striped is-hoverable is-fullwidth" ]
            [ thead []
                (tr []
                    [ th [ class "is-hidden-mobile" ] [ text "" ]
                    , th [] [ text "Account" ]
                    , th [ class "is-hidden-mobile" ] [ text "Address" ]
                    , th [ class "is-hidden-mobile" ] [ text "Type" ]
                    , th [ class "is-hidden-mobile" ] [ text "Last Prd Block" ]
                    , th [ class "is-hidden-mobile" ] [ text "Last Prd At" ]
                    , th [] [ text "Vote Rank" ]
                    , th [] [ text "Status" ]
                    , th [ class "is-hidden-mobile" ] [ text "Head Block" ]
                    ]
                    :: nodesRows
                )
            ]


archivedNodesList : Model -> Html Msg
archivedNodesList model =
    let
        archivedNodes =
            model.nodes
                |> List.filter (\n -> n.isArchived)

        nodesRows =
            if List.length archivedNodes > 0 then
                archivedNodes |> List.map archivedNodeRow
            else
                [ tr []
                    [ td
                        [ colspan 4
                        , class "has-text-centered"
                        ]
                        [ text "There's no Archived Nodes" ]
                    ]
                ]
    in
        table [ class "table is-striped is-hoverable is-fullwidth" ]
            [ thead []
                (tr []
                    [ th [] [ text "" ]
                    , th [] [ text "Account" ]
                    , th [] [ text "Address" ]
                    , th [] [ text "Type" ]
                    ]
                    :: nodesRows
                )
            ]


archivedNodeRow : Node -> Html Msg
archivedNodeRow node =
    let
        actions =
            [ a
                [ onClick (ToggleNodeModal (Just node))
                , title "Edit Node"
                ]
                [ icon "pencil" False False
                ]
            , a
                [ onClick (ShowRestoreConfirmationModal node)
                , title "Restore Node"
                ]
                [ icon "undo" False False ]
            ]
    in
        tr []
            [ td [] actions
            , td []
                [ text node.account
                ]
            , td []
                [ a
                    [ href (nodeAddressLink node)
                    , target "_blank"
                    ]
                    [ text (nodeAddress node) ]
                ]
            , td [] [ nodeTagger node.nodeType ]
            ]


nodeRow : Model -> Node -> Html Msg
nodeRow model node =
    let
        ( bpIcon, bpPauseTxt ) =
            if node.nodeType == BlockProducer && node.bpPaused then
                ( "pause", "Block Production Paused" )
            else
                ( "circle", "" )

        ( iconName, className, pingTxt ) =
            case node.status of
                Online ->
                    ( bpIcon
                    , "has-text-success"
                    , "[" ++ toString node.pingMs ++ "ms]"
                    )

                UnsynchedBlocks ->
                    ( bpIcon
                    , "has-text-warning"
                    , "[Unsync]"
                    )

                Offline ->
                    ( "power-off", "has-text-danger", "" )

                Initial ->
                    ( "clock-o", "", "" )

        status =
            span [ class className, title bpPauseTxt ]
                [ icon iconName False False
                , small [] [ text pingTxt ]
                ]

        currentProducer =
            Maybe.withDefault "-" model.currentProducer

        producerClass =
            if currentProducer == node.account then
                "producer-row"
            else
                ""

        isLogged =
            not (String.isEmpty model.user.token)

        loggedActions =
            if isLogged then
                [ a
                    [ onClick (ToggleNodeModal (Just node))
                    , title "Edit Node"
                    ]
                    [ icon "pencil" False False
                    ]
                , a
                    [ onClick (ShowArchiveConfirmationModal node)
                    , title "Archive Node"
                    ]
                    [ icon "archive" False False
                    ]
                ]
            else
                [ text "" ]

        actions =
            a
                [ onClick (ToggleNodeChainInfoModal (Just node))
                , title "View Node Chain Info"
                ]
                [ icon "info-circle" False False ]
                :: loggedActions

        voteText =
            if node.votePosition == 9999 then
                "?"
            else
                toString node.votePosition

        ( lastPrdAt, lastPrdBlock, votePosition ) =
            case node.nodeType of
                BlockProducer ->
                    ( calcTimeDiffProd node.lastProducedBlockAt model.currentTime
                    , toString node.lastProducedBlock
                    , voteText
                    )

                FullNode ->
                    ( "--", "--", "--" )

                ExternalBlockProducer ->
                    ( calcTimeDiffProd node.lastProducedBlockAt model.currentTime
                    , toString node.lastProducedBlock
                    , voteText
                    )

        alertIcon =
            if node.isWatchable then
                small
                    [ class "has-text-primary is-hidden-mobile"
                    , title "Alerts ON"
                    ]
                    [ icon "bell" False False ]
            else
                small
                    [ class "has-text-grey-light is-hidden-mobile"
                    , title "Alerts OFF"
                    ]
                    [ icon "bell-o" False False ]
    in
        tr [ class producerClass ]
            [ td [ class "is-hidden-mobile" ] actions
            , td []
                [ alertIcon
                , small [ class "node-position is-hidden-mobile" ]
                    [ text (toString node.position ++ ". ") ]
                , text node.account
                ]
            , td [ class "is-hidden-mobile" ]
                [ a
                    [ href (nodeAddressLink node)
                    , target "_blank"
                    ]
                    [ text (nodeAddress node) ]
                ]
            , td [ class "is-hidden-mobile" ] [ nodeTagger node.nodeType ]
            , td [ class "is-hidden-mobile" ] [ text lastPrdBlock ]
            , td [ class "is-hidden-mobile" ] [ text lastPrdAt ]
            , td [] [ text votePosition ]
            , td [] [ status ]
            , td [ class "is-hidden-mobile" ] [ text (toString node.headBlockNum) ]
            ]


settingsContent : Model -> Html Msg
settingsContent model =
    let
        settings =
            model.settingsForm

        ( editButton, footer ) =
            if model.editSettingsForm then
                ( [ text "" ], formFooter SubmitSettings ToggleSettingsForm )
            else if not (String.isEmpty model.user.token) then
                ( [ a [ class "button is-info", onClick ToggleSettingsForm ] [ text "Edit Settings" ] ], text "" )
            else
                ( [ text "" ], text "" )
    in
        div [ class "content" ]
            [ titleMenu
                "Settings"
                editButton
            , form []
                [ columns False
                    [ fieldInput
                        model.isLoading
                        "Principal Block Producer EOS Account"
                        settings.principalNode
                        "cypherglass1"
                        "server"
                        UpdateSettingsFormPrincipalNode
                        (not model.editSettingsForm)
                    , fieldInput
                        model.isLoading
                        "Do Not Repeat Same Error for Interval Minutes"
                        (toString settings.sameAlertIntervalMins)
                        "500"
                        "clock-o"
                        UpdateSettingsFormSameAlertIntervalMins
                        (not model.editSettingsForm)
                    ]
                , div [ class "columns" ]
                    [ div [ class "column" ]
                        [ fieldInput
                            model.isLoading
                            "Monitor Loop Interval (ms)"
                            (toString settings.monitorLoopInterval)
                            "500"
                            "clock-o"
                            UpdateSettingsFormMonitorLoopInterval
                            (not model.editSettingsForm)
                        ]
                    , div [ class "column" ]
                        [ fieldInput
                            model.isLoading
                            "Node Loop Interval (ms)"
                            (toString settings.nodeLoopInterval)
                            "500"
                            "clock-o"
                            UpdateSettingsFormNodeLoopInterval
                            (not model.editSettingsForm)
                        ]
                    , div [ class "column" ]
                        [ fieldInput
                            model.isLoading
                            "Voting and Nodes Report Interval (secs)"
                            (toString settings.calcVotesIntervalSecs)
                            "300"
                            "clock-o"
                            UpdateSettingsFormCalcVotesIntervalSecs
                            (not model.editSettingsForm)
                        ]
                    ]
                , columns False
                    [ fieldInput
                        model.isLoading
                        "Block Production Idle Seconds to Alert"
                        (toString settings.bpToleranceTimeSecs)
                        "180"
                        "bell"
                        UpdateSettingsFormBpToleranceTimeSecs
                        (not model.editSettingsForm)
                    , fieldInput
                        model.isLoading
                        "Unsynched Blocks to emit an Alert"
                        (toString settings.unsynchedBlocksToAlert)
                        "20"
                        "bell"
                        UpdateSettingsFormUnsynchedBlocksToAlert
                        (not model.editSettingsForm)
                    , fieldInput
                        model.isLoading
                        "Failed Pings to emit an Alert"
                        (toString settings.failedPingsToAlert)
                        "20"
                        "bell"
                        UpdateSettingsFormFailedPingsToAlert
                        (not model.editSettingsForm)
                    ]
                , footer
                ]
            ]


pageFooter : Model -> Html Msg
pageFooter model =
    footer [ class "footer" ]
        [ div [ class "container" ]
            [ div [ class "content has-text-centered" ]
                [ p []
                    [ strong []
                        [ text "Cypherglass WINDSHIELD" ]
                    , text " "
                    , a [ href "https://github.com/cypherglassdotcom/windshield" ]
                        [ text "GitHub" ]
                    , text " - One more Special Tool built with love, from  "
                    , a [ href "https://www.cypherglass.com/" ]
                        [ text "Cypherglass.com" ]
                    , text "."
                    , br [] []
                    , text ("UI Version: " ++ model.uiVersion)
                    , text (" / Server Version: " ++ model.monitorState.version)
                    ]
                ]
            ]
        ]


view : Model -> Html Msg
view model =
    let
        modal =
            if model.showHelp then
                helpModal model
            else if model.showNode then
                nodeModal model
            else if model.showArchiveConfirmation then
                archiveConfirmationModal model
            else if model.showRestoreConfirmation then
                restoreConfirmationModal model
            else if model.showNodeChainInfo then
                nodeChainInfoModal model
            else if model.showAdminLogin then
                adminLoginModal model
            else
                text ""
    in
        div []
            [ topMenu model
            , notificationsView model
            , mainContent model
            , pageFooter model
            , modal
            ]
