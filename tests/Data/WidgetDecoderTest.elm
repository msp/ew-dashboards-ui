module Data.WidgetDecoderTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Json.Encode as Encode exposing (object)
import Json.Decode as Decode exposing (..)
import String
import Data.DataSource exposing (DataSource)
import Data.Widget.Author as Author
import Data.Widget as Widget exposing (UUID(..), Body(..), decoder)
import Data.Widget.Adapters.Adapter as Adapter exposing (Adapter(..))
import Data.Widget.Renderer as Renderer exposing (Renderer(..))
import Data.User as User exposing (Username(..))
import Data.UserPhoto as UserPhoto exposing (UserPhoto(..))
import Date


widgetDecoderTest : Test
widgetDecoderTest =
    test "Widget.decoder" <|
        \() ->
            let
                input =
                    """
                    {
                        "widget": {
                            "uuid": "006f0092-5a11-468d-b822-ea57753f45c4",
                            "name": "12 months Table",
                            "body": "12 months Table",
                            "description": "12 months of important data",
                            "dataSources": [{
                                "uuid": "datasource-1234",
                                "name": "12 month financials"
                            }],
                            "adapter": "TABLE",
                            "renderer": "TABLE",
                            "createdAt": "2017-09-04T16:03:55.948Z",
                            "updatedAt": "2017-09-04T16:03:55.948Z",
                            "tagList": [],
                            "author": {
                                "username": "msp",
                                "bio": "beautifully flawed creation ..",
                                "image": "https://static.productionready.io/images/smiley-cyrus.jpg",
                                "following": false
                            },
                            "favorited": false,
                            "favoritesCount": 0,
                            "data": {
                              "data": []
                            }
                        }
                    }
                    """

                expectedDate =
                    Date.fromString "Mon Sep 04 2017 17:03:55 GMT+0100 (BST)" |> Result.withDefault (Date.fromTime 0)

                expectedAuthor =
                    Author.Author
                        (User.Username "msp")
                        (Just "beautifully flawed creation ..")
                        (UserPhoto.UserPhoto <| Just "https://static.productionready.io/images/smiley-cyrus.jpg")
                        False

                expectedDatasources =
                    [ DataSource "datasource-1234" "12 month financials" ]

                decodedOutput =
                    Decode.decodeString (Widget.decoderWithBody |> Decode.field "widget") input
            in
                -- TODO - hmm, why do I need the toString :/
                Expect.equal (toString decodedOutput)
                    (toString
                        (Ok
                            { uuid = Widget.UUID "006f0092-5a11-468d-b822-ea57753f45c4"
                            , name = "12 months Table"
                            , description = "12 months of important data"
                            , dataSources = expectedDatasources
                            , adapter = Adapter.TABLE
                            , renderer = Renderer.TABLE
                            , tags = []
                            , createdAt = expectedDate
                            , updatedAt = expectedDate
                            , favorited = False
                            , favoritesCount = 0
                            , author = expectedAuthor
                            , data = { rows = [] }
                            , body = Body "12 months Table"
                            }
                        )
                    )