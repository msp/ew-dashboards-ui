module Request.Widget
    exposing
        ( FeedConfig
        , ListConfig
        , create
        , defaultFeedConfig
        , defaultListConfig
        , delete
        , feed
        , get
        , list
        , tags
        , toggleFavorite
        , update
        )

import Data.AuthToken as AuthToken exposing (AuthToken, withAuthorization)
import Data.UUID as UUID
import Data.User as User exposing (Username)
import Data.Widget as Widget exposing (Body, Tag, Widget)
import Data.Widget.Feed as Feed exposing (Feed)
import Http
import HttpBuilder exposing (RequestBuilder, withBody, withExpect, withQueryParams)
import Json.Decode as Decode
import Json.Encode as Encode
import Request.Helpers exposing (mockApiUrl)
import Util exposing ((=>))


-- SINGLE --


get : Maybe AuthToken -> UUID.UUID -> Http.Request Widget
get maybeToken slug =
    let
        expect =
            Widget.decoder
                |> Decode.field "widget"
                |> Http.expectJson
    in
        mockApiUrl ("/widgets/" ++ UUID.slugToString slug)
            |> HttpBuilder.get
            |> HttpBuilder.withExpect expect
            |> withAuthorization maybeToken
            |> HttpBuilder.toRequest



-- LIST --


type alias ListConfig =
    { tag : Maybe Tag
    , author : Maybe Username
    , favorited : Maybe Username
    , limit : Int
    , offset : Int
    }


defaultListConfig : ListConfig
defaultListConfig =
    { tag = Nothing
    , author = Nothing
    , favorited = Nothing
    , limit = 20
    , offset = 0
    }


list : ListConfig -> Maybe AuthToken -> Http.Request Feed
list config maybeToken =
    [ "tag" => Maybe.map Widget.tagToString config.tag
    , "author" => Maybe.map User.usernameToString config.author
    , "favorited" => Maybe.map User.usernameToString config.favorited
    , "limit" => Just (toString config.limit)
    , "offset" => Just (toString config.offset)
    ]
        |> List.filterMap maybeVal
        |> buildFromQueryParams "/widgets"
        |> withAuthorization maybeToken
        |> HttpBuilder.toRequest



-- FEED --


type alias FeedConfig =
    { limit : Int
    , offset : Int
    }


defaultFeedConfig : FeedConfig
defaultFeedConfig =
    { limit = 10
    , offset = 0
    }


feed : FeedConfig -> AuthToken -> Http.Request Feed
feed config token =
    [ "limit" => Just (toString config.limit)
    , "offset" => Just (toString config.offset)
    ]
        |> List.filterMap maybeVal
        |> buildFromQueryParams "/widgets/feed"
        |> withAuthorization (Just token)
        |> HttpBuilder.toRequest



-- TAGS --


tags : Http.Request (List Tag)
tags =
    Decode.field "tags" (Decode.list Widget.tagDecoder)
        |> Http.get (mockApiUrl "/tags")



-- FAVORITE --


toggleFavorite : Widget -> AuthToken -> Http.Request Widget
toggleFavorite widget authToken =
    if widget.favorited then
        unfavorite widget.uuid authToken
    else
        favorite widget.uuid authToken


favorite : UUID.UUID -> AuthToken -> Http.Request Widget
favorite =
    buildFavorite HttpBuilder.post


unfavorite : UUID.UUID -> AuthToken -> Http.Request Widget
unfavorite =
    buildFavorite HttpBuilder.delete


buildFavorite :
    (String -> RequestBuilder a)
    -> UUID.UUID
    -> AuthToken
    -> Http.Request Widget
buildFavorite builderFromUrl slug token =
    let
        expect =
            Widget.decoder
                |> Decode.field "widget"
                |> Http.expectJson
    in
        [ mockApiUrl "/widgets", UUID.slugToString slug, "favorite" ]
            |> String.join "/"
            |> builderFromUrl
            |> withAuthorization (Just token)
            |> withExpect expect
            |> HttpBuilder.toRequest



-- CREATE --


type alias CreateConfig record =
    { record
        | name : String
        , description : String
        , tags : List String
    }


type alias EditConfig record =
    { record
        | name : String
        , description : String
    }


create : CreateConfig record -> AuthToken -> Http.Request Widget
create config token =
    let
        expect =
            Widget.decoder
                |> Decode.field "widget"
                |> Http.expectJson

        widget =
            Encode.object
                [ "name" => Encode.string config.name
                , "description" => Encode.string config.description
                , "tagList" => Encode.list (List.map Encode.string config.tags)
                ]

        body =
            Encode.object [ "widget" => widget ]
                |> Http.jsonBody
    in
        mockApiUrl "/widgets"
            |> HttpBuilder.post
            |> withAuthorization (Just token)
            |> withBody body
            |> withExpect expect
            |> HttpBuilder.toRequest


update : UUID.UUID -> EditConfig record -> AuthToken -> Http.Request Widget
update slug config token =
    let
        expect =
            Widget.decoder
                |> Decode.field "widget"
                |> Http.expectJson

        widget =
            Encode.object
                [ "name" => Encode.string config.name
                , "description" => Encode.string config.description
                ]

        body =
            Encode.object [ "widget" => widget ]
                |> Http.jsonBody
    in
        mockApiUrl ("/widgets/" ++ UUID.slugToString slug)
            |> HttpBuilder.put
            |> withAuthorization (Just token)
            |> withBody body
            |> withExpect expect
            |> HttpBuilder.toRequest



-- DELETE --


delete : UUID.UUID -> AuthToken -> Http.Request ()
delete slug token =
    mockApiUrl ("/widgets/" ++ UUID.slugToString slug)
        |> HttpBuilder.delete
        |> withAuthorization (Just token)
        |> HttpBuilder.toRequest



-- HELPERS --


maybeVal : ( a, Maybe b ) -> Maybe ( a, b )
maybeVal ( key, value ) =
    case value of
        Nothing ->
            Nothing

        Just val ->
            Just (key => val)


buildFromQueryParams : String -> List ( String, String ) -> RequestBuilder Feed
buildFromQueryParams url queryParams =
    url
        |> mockApiUrl
        |> HttpBuilder.get
        |> withExpect (Http.expectJson Feed.decoder)
        |> withQueryParams queryParams
