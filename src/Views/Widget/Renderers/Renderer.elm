module Views.Widget.Renderers.Renderer exposing (run)

import Data.Widget as Widget exposing (Body, Widget)
import Data.Widget.Renderer exposing (Renderer(..))
import Data.Widget.Table as Table exposing (Cell, Data)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id, placeholder, src)
import Views.Spinner
import Views.Widget.Renderers.BarChart as BarChart
import Views.Widget.Renderers.HeatMap as HeatMap
import Views.Widget.Renderers.LineAndBarChart as LineAndBarChart
import Views.Widget.Renderers.LineChart as LineChart
import Views.Widget.Renderers.Metric as Metric
import Views.Widget.Renderers.RendererMessage as RendererMessage exposing (Msg(..))
import Views.Widget.Renderers.Table as Table


run : Int -> Int -> Widget Body -> Table.Data -> Html RendererMessage.Msg
run width height widget data =
    case List.isEmpty data.rows of
        True ->
            div [ class "col-md-6" ]
                [ div [ class "spinner-wrapper" ] [ Views.Spinner.spinnerSVG ]
                ]

        False ->
            let
                updatable =
                    True
            in
                case widget.renderer of
                    TABLE ->
                        Table.render width height widget data

                    LINE_CHART ->
                        LineChart.render width height widget data

                    BAR_CHART ->
                        BarChart.render width height widget data

                    LINE_AND_BAR_CHART ->
                        LineAndBarChart.render width height widget data

                    HEAT_MAP ->
                        HeatMap.render width height widget data (not updatable)

                    UPDATABLE_HEAT_MAP ->
                        HeatMap.render width height widget data updatable

                    METRIC ->
                        Metric.render width height widget data
