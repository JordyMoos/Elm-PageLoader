module PageLoader
    exposing
        ( PageState(..)
        , TransitionStatus(..)
        , visualPage
        , defaultDependencyStatusHandler
        , defaultDependencyStatusListHandler
        , defaultProcessLoading
        )

{-| `PageLoader` is a utility library to make loading of pages with dependencies clearer.


# PageLoader

@docs PageState, visualPage
@docs TransitionStatus
@docs defaultDependencyStatusHandler, defaultDependencyStatusListHandler
@docs defaultProcessLoading

-}

import PageLoader.DependencyStatus as DependencyStatus
import PageLoader.Progression as Progression


{-| `PageState`
A page can either be `Loaded` or `Transitioning`.

`Loaded` has a `page` as payload.
`Loaded` is used to display a page when all dependencies are loaded.

`Transitioning` has a `page` (which usually is the previous page) and a `loader` (for the next page) as payload.
The `Transitioning`s job is wait wait until the loader is been promoted to the new page.
In the meantime the transition also holds a previous loaded page which can be used to display to the users.

-}
type PageState page loader
    = Loaded page
    | Transitioning page loader


{-| `visualPage` gathers the `page` from a `PageState`.
-}
visualPage : PageState page loader -> page
visualPage pageState =
    case pageState of
        Loaded page ->
            page

        Transitioning page _ ->
            page


{-| `TransitionStatus` is the result after an loader handles a msg.
The `TransitionStatus` holds the loading data when it is `Pending`.
It hold `data` (often the model of the new page) when the `TransitionStatus` is `Success`.
And it holds an `String` representing an error message when the `TransitionStatus` is `Failed`.
-}
type TransitionStatus model msg data
    = Pending ( model, Cmd msg ) Progression.Progression
    | Success data
    | Failed String


{-| Todo
-}
defaultDependencyStatusListHandler :
    ( model, Cmd msg )
    -> List DependencyStatus.Status
    -> (() -> successData)
    -> TransitionStatus model msg successData
defaultDependencyStatusListHandler ( model, cmd ) dependencyStatuses onSuccessCallback =
    defaultDependencyStatusHandler
        ( model, cmd )
        (DependencyStatus.reduce dependencyStatuses)
        onSuccessCallback


{-| Todo
-}
defaultDependencyStatusHandler :
    ( model, Cmd msg )
    -> DependencyStatus.Status
    -> (() -> successData)
    -> TransitionStatus model msg successData
defaultDependencyStatusHandler ( model, cmd ) dependencyStatus onSuccessCallback =
    case dependencyStatus of
        DependencyStatus.Failed ->
            Failed "Some requests failed"

        DependencyStatus.Pending progression ->
            Pending ( model, cmd ) progression

        DependencyStatus.Success ->
            Success (onSuccessCallback ())


{-| Todo
-}
defaultProcessLoading :
    (String -> page) -- ErrorPageK
    -> (loadingModel -> Progression.Progression -> loader) -- LoadingHome
    -> (loadingMsg -> msg) -- LoadingHomeMsg
    -> (newModel -> page) -- HomePage
    -> (newData -> ( newModel, Cmd newMsg )) -- Home.init
    -> (newMsg -> msg) -- HomeMsg / NoOp
    -> page -- oldPage
    -> TransitionStatus loadingModel loadingMsg newData -- TransitionStatus
    -> ( PageState page loader, Cmd msg )
defaultProcessLoading errorPage loader loaderMsg successPage successPageInit successPageMsg oldPage transitionStatus =
    case transitionStatus of
        Pending ( model, cmd ) progression ->
            ( Transitioning oldPage (loader model progression), Cmd.map loaderMsg cmd )

        Success newData ->
            let
                ( model, cmd ) =
                    successPageInit newData
            in
                ( Loaded (successPage model), Cmd.map successPageMsg cmd )

        Failed error ->
            ( Loaded (errorPage error), Cmd.none )
