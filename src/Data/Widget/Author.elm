module Data.Widget.Author exposing (Author, decoder, init)

import Data.User as User exposing (Username)
import Data.UserPhoto as UserPhoto exposing (UserPhoto)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (custom, decode, required)


decoder : Decoder Author
decoder =
    decode Author
        |> required "username" User.usernameDecoder
        |> required "bio" (Decode.nullable Decode.string)
        |> required "image" UserPhoto.decoder
        |> required "following" Decode.bool


type alias Author =
    { username : Username
    , bio : Maybe String
    , image : UserPhoto
    , following : Bool
    }


init : Author
init =
    Author (User.Username "msp")
        Nothing
        (UserPhoto.UserPhoto <| Just "https://static.productionready.io/images/smiley-cyrus.jpg")
        False
