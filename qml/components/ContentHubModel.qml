import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Content 1.3
import Ubuntu.Components.Popups 1.3
import "../components"

Item {

    id: contentHub
    property url uri: ""
    property var shareObject: null

    signal done ()
    signal copiedToClipboard ()

    Component {
        id: shareDialog
        ContentShareDialog {
            Component.onDestruction: contentHub.done()
        }
    }

    Connections {
        target: UriHandler
        onOpened: openUri ( uris )
    }

    MimeData {
        id: mimeData
        text: ""
    }

    Component {
        id: contentItemComponent
        ContentItem { }
    }

    function openUri ( uris ) {
        // no url
        if (uris.length === 0 ) return
    }

    function toClipboard ( text ) {
        mimeData.text = text
        Clipboard.push( mimeData )
        toast.show ( i18n.tr ( "Copied to clipboard" ) )
    }

    function startImport ( transfer ) {
        console.log("NEW TRANSFER:",JSON.stringify(transfer))
    }

    function share(url, text, contentType) {
        uri = url
        var sharePopup = PopupUtils.open(shareDialog, contentHub, {"contentType" : contentType})
        sharePopup.items.push(contentItemComponent.createObject(contentHub, {"url" : uri, "text": text}))
    }

    function shareLink( url ) {
        share( url, url, ContentType.Links)
    }

    function shareText( text ) {
        share( "", text, ContentType.Text)
    }

    function sharePicture( url, title ) {
        share( url, title, ContentType.Pictures)
    }

    function shareAudio( url, title ) {
        share( url, title, ContentType.Music)
    }

    function shareVideo( url, title ) {
        share( url, title, ContentType.Videos)
    }

    function shareFile( url, title ) {
        share( url, title, ContentType.Documents)
    }

    function shareAll( url, title ) {
        share( url, title, ContentType.All)
    }

}
