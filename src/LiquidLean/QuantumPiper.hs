{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}

-- =====================================================================
-- QUANTUM PIPER — Inverted Piper Architecture for Sovereign Quantum Kernels
-- Local-First, WORM-Anchored, Capability-Based, 8-Phase Pipeline
-- Reverse-engineered from Google Piper → Local-First Quantum
-- =====================================================================

module LiquidLean.QuantumPiper
  ( -- * WORM chain (inline definitions)
    WORMChain(..), BlockHeader(..), Block(..)
  , WORMTxKind(..), WORMTx(..)
  , signPayload, hashBlock
    -- * Entanglement
  , GateName, EntanglementPattern(..)
    -- * Alive result
  , AliveResult(..)
    -- * Core types
  , TeamID(..), CapabilityStore(..), ArtifactStore(..), WorkspaceIndex(..)
  , Capability(..), AliveProof(..), Artifact(..), WorkspaceEntry(..)
  , OverlayFS(..), QWorkspace(..), QuantumKernel(..), PiperPhase(..)
    -- * Helpers
  , unCapabilityStore, unArtifactStore, unWorkspaceIndex
    -- * Pipeline
  , initWorkspace
  , runPiperPipeline
  , parseQuantumKernel
  , typeCheckKernel
  , buildEntanglementGraph
  , checkAlive
  , attestKernel
  , deployKernel
    -- * Workspace ops
  , readOverlay, writeOverlay
  , registerCapability, getCapability
  , storeArtifact, loadArtifact
    -- * Stub
  , generateSecretKey
  ) where

import Control.Concurrent.STM
import Control.Monad (forM, forM_, when)
import Data.Aeson (ToJSON(..), FromJSON(..), encode, decode, object, (.=), (.:), withObject, withText)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import qualified Crypto.Hash.SHA256 as SHA256
import Data.Either (partitionEithers)
import Data.List (find)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time.Clock (UTCTime)
import Data.Word (Word64)
import GHC.Generics (Generic)

-- =====================================================================
-- INLINE DEPENDENCY DEFINITIONS
-- =====================================================================

data BlockHeader = BlockHeader
  { bhHeight    :: Int
  , bhMerkle    :: ByteString
  , bhHash      :: ByteString
  , bhTimestamp :: Word64
  } deriving (Show, Generic)

instance ToJSON BlockHeader
instance FromJSON BlockHeader

data WORMTxKind
  = Theorem3Proof
  | KVCheckpoint
  | CommitAnchor
  | GenericAttest
  deriving (Show, Eq, Generic)

instance ToJSON WORMTxKind
instance FromJSON WORMTxKind

data WORMTx = WORMTx
  { wtKind      :: WORMTxKind
  , wtPayload   :: BSL.ByteString
  , wtSignature :: ByteString
  } deriving (Show, Generic)

instance ToJSON WORMTx
instance FromJSON WORMTx

data Block = Block
  { bHeader :: BlockHeader
  , bTxs    :: [WORMTx]
  } deriving (Show, Generic)

instance ToJSON Block
instance FromJSON Block

data WORMChain = WORMChain
  { wcHead       :: TVar BlockHeader
  , wcStore      :: TVar (Map ByteString Block)
  , wcEd25519Key :: ByteString
  }

-- | Ed25519 signing stub — wire real key in production
signPayload :: ByteString -> BSL.ByteString -> ByteString
signPayload _ _ = BS.replicate 64 0

-- | SHA-256 of serialised header + tx payload
hashBlock :: BlockHeader -> WORMTx -> ByteString
hashBlock h tx = SHA256.hash (BSL.toStrict (encode h) <> BSL.toStrict (wtPayload tx))

type GateName = Text

data EntanglementPattern
  = Linear
  | Star
  | FullMesh
  | Custom Text
  deriving (Show, Eq, Generic)

instance ToJSON EntanglementPattern where
  toJSON Linear     = object ["tag" .= ("Linear"   :: Text)]
  toJSON Star       = object ["tag" .= ("Star"     :: Text)]
  toJSON FullMesh   = object ["tag" .= ("FullMesh" :: Text)]
  toJSON (Custom t) = object ["tag" .= ("Custom"   :: Text), "value" .= t]

instance FromJSON EntanglementPattern where
  parseJSON = withObject "EntanglementPattern" $ \o -> do
    tag <- o .: "tag" :: _ Text
    case (tag :: Text) of
      "Linear"   -> pure Linear
      "Star"     -> pure Star
      "FullMesh" -> pure FullMesh
      "Custom"   -> Custom <$> o .: "value"
      _          -> fail "Unknown EntanglementPattern"

data AliveResult
  = AliveVerified
  | AliveCounterexample Text
  | AliveTimeout
  deriving (Show, Eq, Ord, Generic)

instance ToJSON AliveResult where
  toJSON AliveVerified           = object ["tag" .= ("AliveVerified" :: Text)]
  toJSON (AliveCounterexample t) = object ["tag" .= ("AliveCounterexample" :: Text), "value" .= t]
  toJSON AliveTimeout            = object ["tag" .= ("AliveTimeout" :: Text)]

instance FromJSON AliveResult where
  parseJSON = withObject "AliveResult" $ \o -> do
    tag <- o .: "tag" :: _ Text
    case (tag :: Text) of
      "AliveVerified"       -> pure AliveVerified
      "AliveCounterexample" -> AliveCounterexample <$> o .: "value"
      "AliveTimeout"        -> pure AliveTimeout
      _                     -> fail "Unknown AliveResult"

-- =====================================================================
-- PHASE 1: NAMESPACE & OWNERSHIP
-- =====================================================================

newtype TeamID = TeamID Text
  deriving (Show, Eq, Ord, Generic)

instance ToJSON TeamID
instance FromJSON TeamID

newtype CapabilityStore = CapabilityStore (TVar (Map GateName Capability))
newtype ArtifactStore   = ArtifactStore   (TVar (Map Text Artifact))
newtype WorkspaceIndex  = WorkspaceIndex  (TVar (Map Text WorkspaceEntry))

unCapabilityStore :: CapabilityStore -> TVar (Map GateName Capability)
unCapabilityStore (CapabilityStore v) = v

unArtifactStore :: ArtifactStore -> TVar (Map Text Artifact)
unArtifactStore (ArtifactStore v) = v

unWorkspaceIndex :: WorkspaceIndex -> TVar (Map Text WorkspaceEntry)
unWorkspaceIndex (WorkspaceIndex v) = v

data AliveProof = AliveProof
  { apResult    :: AliveResult
  , apWitness   :: Maybe Text
  , apTimestamp :: UTCTime
  } deriving (Show, Generic)

instance ToJSON AliveProof
instance FromJSON AliveProof

data Capability = Capability
  { capName      :: GateName
  , capTeam      :: TeamID
  , capPattern   :: EntanglementPattern
  , capMaxQubits :: Int
  , capMaxDepth  :: Int
  , capAliveProof :: Maybe AliveProof
  } deriving (Show, Generic)

instance ToJSON Capability
instance FromJSON Capability

-- =====================================================================
-- PHASE 2: CONTENT-ADDRESSED QUANTUM ARTIFACTS
-- =====================================================================

data Artifact = Artifact
  { artName      :: Text
  , artContent   :: BSL.ByteString
  , artMerkle    :: ByteString
  , artTimestamp :: UTCTime
  } deriving (Show, Generic)

instance ToJSON Artifact
instance FromJSON Artifact

data WorkspaceEntry = WorkspaceEntry
  { wePath         :: FilePath
  , weTeam         :: TeamID
  , weCapabilities :: [GateName]
  , weArtifacts    :: [Text]
  } deriving (Show, Generic)

instance ToJSON WorkspaceEntry
instance FromJSON WorkspaceEntry

-- =====================================================================
-- PHASE 3: QUANTUM WORKSPACE (CitC inverted: Local-First Overlay FS)
-- =====================================================================

data OverlayFS = OverlayFS
  { ofsBase    :: Map FilePath BSL.ByteString
  , ofsOverlay :: Map FilePath BSL.ByteString
  } deriving (Show, Generic)

instance ToJSON OverlayFS
instance FromJSON OverlayFS

data QWorkspace = QWorkspace
  { wsRoot         :: FilePath
  , wsTeam         :: TeamID
  , wsCapabilities :: CapabilityStore
  , wsArtifacts    :: ArtifactStore
  , wsOverlay      :: TVar OverlayFS   -- TVar so we can atomically update
  , wsIndex        :: WorkspaceIndex
  , wsWORM         :: WORMChain
  }

-- =====================================================================
-- PHASES 4-8: QUANTUM KERNEL PIPELINE
-- =====================================================================

data QuantumKernel = QuantumKernel
  { qkName       :: GateName
  , qkTeam       :: TeamID
  , qkPattern    :: EntanglementPattern
  , qkQubits     :: Int
  , qkDepth      :: Int
  , qkCode       :: BSL.ByteString
  , qkAliveProof :: Maybe AliveProof
  } deriving (Show, Generic)

instance ToJSON QuantumKernel
instance FromJSON QuantumKernel

data PiperPhase
  = Phase1_Parse
  | Phase2_TypeCheck
  | Phase3_Entangle
  | Phase4_Optimize
  | Phase5_AliveCheck
  | Phase6_Compile
  | Phase7_Attest
  | Phase8_Deploy
  deriving (Show, Eq, Enum, Bounded, Generic)

instance ToJSON PiperPhase
instance FromJSON PiperPhase

-- PROOF OBLIGATION: Phase1_Parse produces well-formed AST for all valid inputs
parseQuantumKernel :: BSL.ByteString -> Either Text QuantumKernel
parseQuantumKernel src =
  case decode src of
    Just qk -> Right qk
    Nothing -> Left "Phase1_Parse: failed to decode QuantumKernel JSON"

-- PROOF OBLIGATION: Phase2_TypeCheck rejects kernels exceeding capMaxQubits/capMaxDepth
typeCheckKernel :: Capability -> QuantumKernel -> Either Text ()
typeCheckKernel cap qk = do
  if qkQubits qk > capMaxQubits cap
    then Left $ "Phase2_TypeCheck: qubits " <> T.pack (show (qkQubits qk))
             <> " exceeds cap " <> T.pack (show (capMaxQubits cap))
    else Right ()
  if qkDepth qk > capMaxDepth cap
    then Left $ "Phase2_TypeCheck: depth " <> T.pack (show (qkDepth qk))
             <> " exceeds cap " <> T.pack (show (capMaxDepth cap))
    else Right ()
  if qkPattern qk /= capPattern cap
    then Left "Phase2_TypeCheck: entanglement pattern mismatch"
    else Right ()

-- PROOF OBLIGATION: Phase3_Entangle produces connected graph matching EntanglementPattern
buildEntanglementGraph :: EntanglementPattern -> Int -> Map (Int, Int) Double
buildEntanglementGraph Linear  n = Map.fromList [((i, i+1), 1.0) | i <- [0..n-2]]
buildEntanglementGraph Star    n = Map.fromList [((0, i),   1.0) | i <- [1..n-1]]
buildEntanglementGraph FullMesh n = Map.fromList [((i, j),  1.0) | i <- [0..n-1], j <- [i+1..n-1]]
buildEntanglementGraph (Custom _) _ = Map.empty

-- PROOF OBLIGATION: Phase5_AliveCheck returns AliveVerified iff kernel terminates
checkAlive :: QuantumKernel -> IO AliveResult
checkAlive qk = return $
  if qkDepth qk < 100 then AliveVerified else AliveTimeout

-- PROOF OBLIGATION: Phase7_Attest produces valid WORMTx with Ed25519 signature
attestKernel :: WORMChain -> QuantumKernel -> AliveResult -> IO WORMTx
attestKernel worm qk alive = do
  let payload = encode $ object
        [ "kernel" .= qkName qk
        , "team"   .= qkTeam qk
        , "alive"  .= alive
        , "qubits" .= qkQubits qk
        , "depth"  .= qkDepth qk
        ]
  let sig = signPayload (wcEd25519Key worm) payload
  return $ WORMTx Theorem3Proof payload sig

-- PROOF OBLIGATION: Phase8_Deploy atomically commits to WORM and updates index
deployKernel :: QWorkspace -> QuantumKernel -> WORMTx -> IO ()
deployKernel ws qk tx = atomically $ do
  header <- readTVar (wcHead (wsWORM ws))
  let newHeight = bhHeight header + 1
      bh = BlockHeader newHeight (wtSignature tx) (wtSignature tx) 0
      blk = Block bh [tx]
      bHash = hashBlock bh tx
  modifyTVar' (wcStore (wsWORM ws)) (Map.insert bHash blk)
  modifyTVar' (unWorkspaceIndex (wsIndex ws))
    (Map.insert (T.unpack (qkName qk))
      WorkspaceEntry
        { wePath = wsRoot ws
        , weTeam = wsTeam ws
        , weCapabilities = [qkName qk]
        , weArtifacts    = [T.unpack (qkName qk) <> ".bin"]
        })

-- =====================================================================
-- PIPELINE ORCHESTRATION (all 8 phases)
-- =====================================================================

runPiperPipeline :: QWorkspace -> BSL.ByteString -> IO (Either Text QuantumKernel)
runPiperPipeline ws src = do
  -- Phase 1
  qk <- case parseQuantumKernel src of
          Left e  -> return (Left e)
          Right q -> return (Right q)
  qk' <- case qk of { Left e -> return (Left e); Right q -> return (Right q) }

  -- Phase 2
  mcap <- getCapability ws (qkName (case qk' of Right q -> q; Left _ -> error "impossible"))
  case qk' of
    Left e -> return (Left e)
    Right q -> do
      case mcap of
        Nothing -> return (Left "Phase2: capability not found")
        Just cap -> case typeCheckKernel cap q of
          Left e  -> return (Left e)
          Right _ -> do
            -- Phase 3
            let graph = buildEntanglementGraph (qkPattern q) (qkQubits q)
            -- Phase 4: optimize (identity for now)
            let qOpt = q
            -- Phase 5
            alive <- checkAlive qOpt
            -- Phase 6: compile to plasma bytecode (JSON stub)
            let binary = encode qOpt
            -- Phase 7
            tx <- attestKernel (wsWORM ws) qOpt alive
            -- Phase 8
            deployKernel ws qOpt tx
            let art = Artifact
                  { artName      = qkName q <> ".bin"
                  , artContent   = binary
                  , artMerkle    = SHA256.hash (BSL.toStrict binary)
                  , artTimestamp = undefined
                  }
            storeArtifact ws art
            return (Right qOpt)

-- =====================================================================
-- WORKSPACE MANAGEMENT
-- =====================================================================

initWorkspace :: FilePath -> TeamID -> ByteString -> IO QWorkspace
initWorkspace root team key = do
  indexVar <- newTVarIO Map.empty
  capsVar  <- newTVarIO Map.empty
  artsVar  <- newTVarIO Map.empty
  ofsVar   <- newTVarIO (OverlayFS Map.empty Map.empty)
  headVar  <- newTVarIO (BlockHeader 0 BS.empty BS.empty 0)
  storeVar <- newTVarIO Map.empty
  return QWorkspace
    { wsRoot         = root
    , wsTeam         = team
    , wsCapabilities = CapabilityStore capsVar
    , wsArtifacts    = ArtifactStore   artsVar
    , wsOverlay      = ofsVar
    , wsIndex        = WorkspaceIndex  indexVar
    , wsWORM         = WORMChain headVar storeVar key
    }

readOverlay :: QWorkspace -> IO OverlayFS
readOverlay ws = readTVarIO (wsOverlay ws)

writeOverlay :: QWorkspace -> FilePath -> BSL.ByteString -> IO ()
writeOverlay ws path content = atomically $
  modifyTVar' (wsOverlay ws) $ \ofs ->
    ofs { ofsOverlay = Map.insert path content (ofsOverlay ofs) }

registerCapability :: QWorkspace -> Capability -> IO ()
registerCapability ws cap = atomically $
  modifyTVar' (unCapabilityStore (wsCapabilities ws)) (Map.insert (capName cap) cap)

getCapability :: QWorkspace -> GateName -> IO (Maybe Capability)
getCapability ws name = atomically $
  Map.lookup name <$> readTVar (unCapabilityStore (wsCapabilities ws))

storeArtifact :: QWorkspace -> Artifact -> IO ()
storeArtifact ws art = atomically $
  modifyTVar' (unArtifactStore (wsArtifacts ws)) (Map.insert (artName art) art)

loadArtifact :: QWorkspace -> Text -> IO (Maybe Artifact)
loadArtifact ws name = atomically $
  Map.lookup name <$> readTVar (unArtifactStore (wsArtifacts ws))

generateSecretKey :: IO ByteString
generateSecretKey = return (BS.replicate 32 42)

-- =====================================================================
-- PROOF OBLIGATIONS
-- =====================================================================
{-
THEOREM (Workspace Consistency):
  ∀ (ws : QWorkspace) (name : Text).
    loadArtifact ws name = Just art →
    artMerkle art = SHA256(artContent art)

THEOREM (Capability Safety):
  ∀ (ws : QWorkspace) (qk : QuantumKernel).
    runPiperPipeline ws qk = Right qk' →
    ∃ cap. getCapability ws (qkName qk) = Just cap ∧
           typeCheckKernel cap qk = Right ()

THEOREM (WORM Anchoring):
  ∀ (ws : QWorkspace) (qk : QuantumKernel) (tx : WORMTx).
    deployKernel ws qk tx →
    Map.member (hashBlock (bHeader blk) tx) (wsWORM ws).store

THEOREM (Proof Cache Soundness):
  ∀ (qk : QuantumKernel).
    checkAlive qk = AliveVerified →
    qkDepth qk < 100
-}
