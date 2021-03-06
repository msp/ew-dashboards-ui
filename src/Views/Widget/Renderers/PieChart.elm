module Views.Widget.Renderers.PieChart exposing (render)

import Array exposing (..)
import Color
import Color.Convert
import Data.Widget as Widget exposing (Body, Widget)
import Data.Widget.Adapters.Adapter exposing (Adapter(..))
import Data.Widget.Adapters.TableAdapter as TableAdapter exposing (Orientation(..))
import Data.Widget.Config as RendererConfig
import Data.Widget.Table as Table exposing (Cell, Data)
import Html exposing (..)
import List.Extra
import NumberParser
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Views.Widget.Renderers.Config as ViewConfig
import Views.Widget.Renderers.Utils as Utils exposing (..)
import Visualization.Scale as Scale exposing (category10)
import Visualization.Shape as Shape exposing (defaultPieConfig)
import Views.Widget.Renderers.ChartLegend as ChartLegend


-- Public ----------------------------------------------------------------------


render : RendererConfig.Config -> Int -> Int -> Widget -> Table.Data -> Html msg
render optionalRendererConfig width height widget data =
    case widget.adapter of
        TABLE optionalAdapterConfig ->
            let
                vTable =
                    TableAdapter.adapt optionalAdapterConfig data Vertical

                dataAsLabelValueTuples =
                    List.map
                        (\row ->
                            let
                                label =
                                    List.head row |> Maybe.withDefault "label"

                                value =
                                    List.Extra.last row |> Maybe.withDefault "0"
                            in
                                ( label, value )
                        )
                        vTable.rows

                calculatedWidth =
                    ViewConfig.calculateWidth optionalRendererConfig width

                calculatedHeight =
                    ViewConfig.calculateHeight optionalRendererConfig height

                body =
                    div []
                        [ Utils.renderTitleFrom widget
                        , view calculatedWidth calculatedHeight dataAsLabelValueTuples
                        ]
            in
                div [ class <| ViewConfig.colSpanClass optionalRendererConfig ++ " widget" ] <|
                    Utils.renderWidgetBody data body

        _ ->
            p [ class "data" ] [ Html.text "Sorry, I can only render pie charts from a TABLE adapter right now" ]



-- Private ---------------------------------------------------------------------


padding : Float
padding =
    ViewConfig.mediumPadding


lineColours : Array Color.Color
lineColours =
    Array.fromList (List.reverse Scale.category10)


getLineColour : Int -> String
getLineColour index =
    get index lineColours
        |> Maybe.withDefault Color.black
        |> Color.Convert.colorToHex


radius : Int -> Int -> Float
radius width height =
    List.minimum [ width, (height // 2) ]
        |> Maybe.withDefault width
        |> toFloat


legendLabel : Int -> String -> Svg msg
legendLabel index labelText =
    ChartLegend.createVerticalLabel index labelText "■" getLineColour


renderLegend :
    Int
    -> Maybe (List String)
    -> List (Svg msg)
renderLegend top seriesLabels =
    let
        labels =
            ChartLegend.createLabels seriesLabels legendLabel
    in
        ChartLegend.renderTopLeftAligned top (round padding) labels


view : Int -> Int -> List ( Cell, Cell ) -> Svg msg
view width height data =
    let
        values =
            List.map
                (\val ->
                    NumberParser.fromString (Tuple.second val)
                )
                data

        labels =
            List.map (\d -> Tuple.first d ++ ": " ++ Tuple.second d) data

        pieData =
            Shape.pie { defaultPieConfig | outerRadius = (radius width height) } values

        makeSlice index datum =
            Svg.path
                [ d (Shape.arc datum)
                , Svg.Attributes.style ("fill:" ++ (getLineColour index) ++ "; stroke: #fff;")
                , Svg.Attributes.class "segment"
                ]
                [ Svg.title []
                    [ Svg.text <|
                        (makeTitle index)
                    ]
                ]

        makeTitle index =
            let
                ( label, amount ) =
                    List.Extra.getAt index data
                        |> Maybe.withDefault ( "??", "--" )
            in
                label ++ ": " ++ amount

        makeLabel slice ( label, value ) =
            text_
                [ transform
                    ("translate"
                        ++ toString
                            (Shape.centroid
                                { slice
                                    | innerRadius = (radius width height) - 40
                                    , outerRadius = (radius width height) - 20
                                }
                            )
                    )
                , dy ".35em"
                , textAnchor "middle"
                ]
                [ Svg.text label ]
    in
        svg [ Svg.Attributes.width (toString width ++ "px"), Svg.Attributes.height (toString height ++ "px") ] <|
            List.concat
                [ [ g [ transform ("translate(" ++ toString (width // 2) ++ "," ++ toString (height // 2) ++ ")") ]
                        [ g [] <| List.indexedMap makeSlice pieData
                          -- , g [] <| List.map2 makeLabel pieData data
                        ]
                  ]
                , renderLegend 50 (Just labels)
                ]
