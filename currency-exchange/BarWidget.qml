import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Rectangle {
  id: root

  // Required properties injected by PluginBarWidgetSlot
  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  // Access Main.qml instance for shared state/functions
  readonly property var main: pluginApi?.mainInstance

  // Configuration
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Settings
  readonly property string displayMode: cfg.widgetDisplayMode || defaults.widgetDisplayMode || "icon"
  readonly property string fromCurrency: cfg.sourceCurrency || defaults.sourceCurrency || "USD"
  readonly property string toCurrency: cfg.targetCurrency || defaults.targetCurrency || "EUR"

  // State from Main.qml
  readonly property bool loading: main?.loading || false
  readonly property bool loaded: main?.loaded || false
  readonly property real rate: main ? main.getRate(fromCurrency, toCurrency) : 0

  // Bar orientation
  readonly property string barPosition: Settings.data.bar.position || "top"
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"

  // Sizing
  implicitWidth: isVertical ? Style.capsuleHeight : contentWidth
  implicitHeight: Style.capsuleHeight

  readonly property real contentWidth: {
    var iconWidth = Style.toOdd(Style.capsuleHeight * 0.4);
    if (displayMode === "icon") {
      return iconWidth + Style.marginM * 2;
    }
    var textWidth = rateText.implicitWidth + Style.marginM;
    if (displayMode === "compact") {
      return iconWidth + textWidth + Style.marginM * 2;
    }
    // full mode
    return iconWidth + textWidth + Style.marginM * 2;
  }

  // Styling
  color: Style.capsuleColor
  radius: Style.radiusM
  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth

  // Display text based on mode
  readonly property string displayText: {
    if (loading) return "...";
    if (!loaded || rate === 0) return "--";
    // compact mode
    if (displayMode === "compact") {
      return main.formatNumber(rate);
    }
    // full mode
    return "1 " + fromCurrency + " = " + main.formatNumber(rate) + " " + toCurrency;
  }

  readonly property string tooltipText: {
    if (loading) return "Loading exchange rates...";
    if (!loaded) return "Could not load rates, check your internet connection.";
    return "1 " + fromCurrency + " = " + main.formatNumber(rate) + " " + toCurrency + "\nClick to open converter";
  }

  // Horizontal layout
  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Style.marginS
    anchors.rightMargin: Style.marginS
    spacing: Style.marginS
    visible: !isVertical

    // Loading spinner
    NIcon {
      icon: "loader"
      color: Color.mOnSurfaceVariant
      Layout.alignment: Qt.AlignVCenter
      visible: loading

      RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 1000
        loops: Animation.Infinite
      }
    }

    NIcon {
      icon: "currency-dollar"
      applyUiScale: false
      Layout.alignment: Qt.AlignVCenter
      visible: !loading
    }

    NText {
      id: rateText
      text: displayText
      color: Color.mOnSurface
      pointSize: Style.barFontSize
      font.weight: Font.Medium
      applyUiScale: false
      Layout.alignment: Qt.AlignVCenter
      visible: displayMode !== "icon"
    }
  }

  // Vertical layout - icon only option
  ColumnLayout {
    anchors.fill: parent
    spacing: Style.marginS
    visible: isVertical

    // Loading spinner
    NIcon {
      icon: "loader"
      color: Color.mOnSurfaceVariant
      Layout.alignment: Qt.AlignVCenter
      visible: loading

      RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 1000
        loops: Animation.Infinite
      }
    }

    NIcon {
      icon: "currency-dollar"
      Layout.alignment: Qt.AlignHCenter
      visible: !loading
    }

  }

  // Mouse interaction
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton

    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(screen, this);
      }
    }

    onEntered: {
      TooltipService.show(root, tooltipText, BarService.getTooltipDirection());
    }

    onExited: {
      TooltipService.hide();
    }
  }

  // Fetch rates on load
  Component.onCompleted: {
    if (main) {
      main.fetchRates();
    }
  }
}
