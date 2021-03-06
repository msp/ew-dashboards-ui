module Request.Helpers exposing (apiUrl, mockApiUrl)


apiUrl : String -> String
apiUrl str =
    "https://conduit.productionready.io/api" ++ str


mockApiUrl : String -> String
mockApiUrl str =
    "/api" ++ str ++ ".json"
