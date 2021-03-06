module Data.Dashboard exposing (Dashboard, decoder)

import Data.UUID as UUID
import Data.Widget as Widget exposing (..)
import Data.Widget.Author as Author exposing (Author)
import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra
import Json.Decode.Pipeline as Pipeline exposing (custom, decode, required)


decoder : Decoder Dashboard
decoder =
    decode Dashboard
        |> required "uuid" (Decode.map UUID.UUID Decode.string)
        |> required "name" Decode.string
        |> required "slug" Decode.string
        |> required "description" Decode.string
        |> required "createdAt" Json.Decode.Extra.date
        |> required "updatedAt" Json.Decode.Extra.date
        |> required "author" Author.decoder
        |> required "favorited" Decode.bool
        |> required "favoritesCount" Decode.int
        |> required "widgets" (Decode.list Widget.decoder)


type alias Dashboard =
    { uuid : UUID.UUID
    , name : String
    , slug : String
    , description : String
    , createdAt : Date
    , updatedAt : Date
    , author : Author
    , favorited : Bool
    , favoritesCount : Int
    , widgets : List Widget
    }
