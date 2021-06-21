import QtQuick 2.9
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3

import "../components"

Page {
    id: instancePickerPage
    anchors.fill: parent

    property bool searchRunning:false
    property var lastList: []
    property var updateTime: null

    Component.onCompleted: getSample ()

	WorkerScript {
		id:asyncProcess
		source:'../components/jslibs/FilterPods.js'
		onMessage:instanceList.writeInList (  messageObject.reply );
	}

	CachedHttpRequest {
		id:cachedRequest

		url:"https://the-federation.info/graphql"
		getData: {
			"operationName" : "Platform",
			"variables" : '{"name":"lemmy"}',
			"query" : "query Platform($name: String!) {  platforms(name: $name) {    name    code    displayName    description    tagline    website    icon    __typename  }  nodes(platform: $name) {    id    name    version    openSignups    host    platform {      name      icon      __typename    }    countryCode    countryFlag    countryName    services {      name      __typename    }    __typename  }  statsGlobalToday(platform: $name) {    usersTotal    usersHalfYear    usersMonthly    localPosts    localComments    __typename  }  statsNodes(platform: $name) {    node {      id      __typename    }    usersTotal    usersHalfYear    usersMonthly    localPosts    localComments    __typename  }}"
		}

		onResponseDataUpdated : {
			searchRunning = false;
			for(var j in  response.data.nodes) {
				response.data.nodes[j].stats= {};
			for(var i in response.data.statsNodes) {
					if(response.data.statsNodes[i].node.id == response.data.nodes[j].id ) {
						response.data.nodes[j].stats = response.data.statsNodes[i];
					}
				}
			}
			var nodes = response.data.nodes;
			lastList = nodes;
			updateTime = Date.now();
			asyncProcess.sendMessage( {searchTerm : customInstanceInput.displayText , inData : nodes });
		}

		onRequestError: {
			console.log(errorResults)
			instancePickerPage.errorOnRequest();
		}

		onRequestStarted: {
			loading.running = true;
			loadingError.visible = false;
		}
	}

    function getSample () {
		if(searchRunning) { return; }
		searchRunning = true;

		cachedRequest.send("getinstances")
    }

    function errorOnRequest() {
			loadingError.visible = true;
			loading.visible = false;
	}

    function search ()  {

		var searchTerm = customInstanceInput.displayText.toLowerCase();
		//If  the  search starts with https then go to the url
		if(searchTerm.indexOf("https") == 0 ) {
			appSettings.instance = searchTerm
			mainStack.push (Qt.resolvedUrl("./LemmyWebview.qml"))
			return
		}

		if(updateTime < Date.now()-60000) {
			loading.visible = true
			loadingError.visible = false;
			instanceList.children = ""
			getSample();
		} else {
			asyncProcess.sendMessage( {searchTerm : searchTerm ,onlyReg: onlyWithRegChkBox.checked, inData : lastList });
		}
    }



    header: PageHeader {
        id: header
        title: i18n.tr('Choose a Lemmy instance')
        StyleHints {
            foregroundColor: theme.palette.normal.backgroundText
            backgroundColor: theme.palette.normal.background
        }
        trailingActionBar {
            actions: [
            Action {
                text: i18n.tr("Info")
                iconName: "info"
                onTriggered: {
                    mainStack.push(Qt.resolvedUrl("./Information.qml"))
                }
            },
            Action {
                iconName: "search"
                onTriggered: {
                    if ( customInstanceInput.displayText == "" ) {
                        customInstanceInput.focus = true
                    } else search ()
                }
            }
            ]
        }
        extension:	Item {
			 anchors {
				left: parent.left
				leftMargin: units.gu(2)
				bottom: parent.bottom
			}
			height: units.gu(4)

			CheckBox {
				id:onlyWithRegChkBox
				StyleHints {
					foregroundColor:theme.palette.normal.backgroundTertiaryText
				}
				text: i18n.tr("Only show nodes that allow registration")
				checked: false;
				onTriggered:search();
			}
		}
    }

    ActivityIndicator {
        id: loading
        visible: true
        running: true
        anchors.centerIn: parent
    }

    Label {
        id: loadingError
		anchors.centerIn: parent
		visible:false
        text : i18n.tr("Error loading instances nodes")
		color:theme.palette.normal.negative
    }


    TextField {
        id: customInstanceInput
        anchors.top: header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: height
        width: parent.width - height
        placeholderText: i18n.tr("Search or enter a custom address")
        Keys.onReturnPressed: search()
    }

    ScrollView {
        id: scrollView
        width: parent.width
        height: parent.height - header.height - 3*customInstanceInput.height
        anchors.top: customInstanceInput.bottom
        anchors.topMargin: customInstanceInput.height
        contentItem: Column {
            id: instanceList
            width: root.width


            // Write a list of instances to the ListView
            function writeInList ( list ) {
                instanceList.children = ""
                loading.visible = false
				loadingError.visible = false;
                list.sort(function(a,b) {return !a.stats.usersTotal ? (!b.stats.usersTotal ? 0 : 1) : (!b.stats.usersTotal ? -1 : parseFloat(b.stats.usersTotal) - parseFloat(a.stats.usersTotal));});
                for ( var i = 0; i < list.length; i++ ) {
                    var item = Qt.createComponent("../components/InstanceItem.qml")
                    item.createObject(this, {
                        "text": list[i].name,
                        "country": list[i].countryName != null ? list[i].countryName : "",
                        "version": list[i].version != null ? list[i].version : "",
						"users": list[i].stats.usersTotal != null ? list[i].stats.usersTotal : "",
                        "iconSource":  list[i].thumbnail != null ? list[i].thumbnail : "../../assets/logo.svg",
						"status":  list[i].openSignups != null ? list[i].openSignups : 0,
						"rating":  list[i].score != null ? list[i].score : 0
                    })
                }
            }
        }
    }

    Label {
		id:noResultsLabel
		visible: !instanceList.children.length && !loading.visible && !loadingError.visible
		anchors.centerIn: scrollView;
		text:customInstanceInput.length ? i18n.tr("No results found for search : %1").arg(customInstanceInput.displayText) :  i18n.tr("No results returned from server");
	}

}
