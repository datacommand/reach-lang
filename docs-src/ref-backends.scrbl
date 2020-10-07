#lang scribble/manual
@(require "lib.rkt")

@title[#:version reach-vers #:tag "ref-backends" #:style 'toc]{Participant Backends}

This section describes the @tech{participant} @tech{backends}
supported by Reach version @|reach-vers|.

@local-table-of-contents[#:style 'immediate-only]

@section[#:tag "ref-backend-js"]{JavaScript}

The Reach JavaScript @tech{backend} produces a compilation output named @filepath{input.export.mjs} which exports an asynchronous function for each @tech{participant}.
This will normally be imported by writing:

@(mint-define! '("backend"))
@js{
 import * as backend from './build/index.main.mjs';
}

Each function accepts three arguments: @jsin{stdlib}, @jsin{ctc}, and @jsin{interact}. These functions should be called by the @tech{frontend}.
For example, if a Reach program contains a participant named @reachin{'A'} in the argument to @reachin{Reach.App}, then the JavaScript backend will include a function named @jsin{A}.

The @(mint-define! '("stdlib")) @jsin{stdlib} argument is provided by either
@itemlist[
 @item{the module @litchar{@"@"reach-sh/stdlib/ETH.mjs};}
 @item{the module @litchar{@"@"reach-sh/stdlib/ALGO.mjs};}
 @item{the module @litchar{@"@"reach-sh/stdlib/FAKE.mjs}; or,}
 @item{the @jsin{async} function @litchar{loadStdlib} from @litchar{@"@"reach-sh/stdlib/loader.mjs}.}
]

The @jsin{ctc} argument is the result of a call to @jsin{acc.deploy} or @jsin{acc.attach}.

The @jsin{interact} argument is an object matching the @tech{participant interact interface} for the corresponding @tech{participant}.

The JavaScript backend also provides an export named @jsin{_version}, which is a string representation of the Reach version used to compile the program.
For example, the version of Reach used to produce this documentation would contain the string @jsin{'@|reach-vers|'}.

Finally, the backend will provide an export named @jsin{_Connectors}, which is an opaque object representing the @tech{connectors} this app was compiled to.

@subsection[#:tag "ref-backend-js-guarantees"]{Guarantees}

This backend does not guarantee that values in a positive position in a @tech{participant interact interface}, that are later passed to a negative position in a @tech{participant interact interface}, will be identical, in the sense of JavaScript's @jsin{===} operator, to the original value.
In other words, this backend does not ensure that Reach programs are parametric over JavaScript values that they interact with.

Positive and negative are best understood by example with a function type: a positive position is supplied by the function, such as the result; while a negative position is supplied by the caller, such as the arguments.
These notions generalize, however, to higher (and lower) order contexts.
In the case of Reach, this means that non-function values in a @tech{participant interact interface} are positive.

For example, if the Reach program,

@reach{
 Reach.App({},
  [["A", { get: Bytes, give: Fun([Bytes], Bool) }]],
  (A) => {
   A.only(() => {
    const x = interact.give(interact.get); });
   A.publish(x);
   commit(); }); }

is given the @jsin{interact} object,

@js{
 const x = "A string";
 { get: x,
   give: (str) => x === str } }

then it is not guaranteed that @reachin{A} will publish @reachin{true}, because the @jsin{str} given to @jsin{give} may not be identical to @jsin{x}.
(However, they are @jsin{bytesEq}.)

@subsection[#:tag "ref-backend-js-loader.mjs"]{@tt{loader.mjs}}

The @tt{loader.mjs} module exports the following functions
that might help you write code that is portable to multiple consensus networks.

@(hrule)

@(mint-define! '("canonicalizeConnectorMode"))
@js{
  canonicalizeConnectorMode(string) => string
}

Expands a connector mode prefix
to its full, canonical name. The canonical connector modes are:

@js{
  'ETH-test-dockerized-geth'   // Default for ETH, ETH-test, and ETH-test-dockerized
  'ETH-test-embedded-ganache'  // Default for ETH-test-embedded
  'FAKE-test-embedded-mock'    // Default for FAKE, FAKE-test, and FAKE-test-embedded
  'ALGO-test-dockerized-algod' // Default for ALGO, ALGO-test, and ALGO-test-dockerized
}

@(hrule)

@(mint-define! '("getConnectorMode"))
@js{
  getConnectorMode() => string
}

Returns the canonicalized connector mode, based on the
@jsin{process.env.REACH_CONNECTOR_MODE} environment variable.
If the variable is missing or empty, it will return the canonicalized form of @jsin{'ETH'}.

@(hrule)

@(mint-define! '("getConnector"))
@js{
  getConnector() => string
}

Returns the first piece of @jsin{getConnectorMode()},
which indicates the abbreviated name of the network being connected to.
Connectors are one of the following: @jsin{['ETH', 'FAKE', 'ALGO']}.

@(hrule)

@(mint-define! '("loadStdLib"))
@js{
  loadStdlib(connectorMode) => Promise<stdlib>
}

Returns a Promise for a stlib based on the provided @jsin{connectorMode} string.
You may omit the @jsin{connectorMode} argument, in which case
@jsin{getConnectorMode()} will be used to select the correct stdlib.

@subsection[#:tag "ref-backend-js-stdlib"]{Standard Library}

The @jsin{stdlib} modules export the following functions that might be used in this @tech{frontend}:

@(hrule)
@(mint-define! '("newAccountFromMnemonic"))
@js{
 newAccountFromMnemonic() => Promise<acc> }

Returns a Promise for a Reach @tech{account} abstraction for an @tech{account} on the @tech{consensus network} specified by the given mnemonic phrase.
The details of the mnemonic phrase encoding are specified uniquely to the @tech{consensus network}.

@(hrule)
@(mint-define! '("newTestAccount"))
@js{
 newTestAccount(balance) => Promise<acc> }

Returns a Promise for a Reach @tech{account} abstraction for a new @tech{account} on the @tech{consensus network} with a given balance of @tech{network tokens}. This can only be used in private testing scenarios, as it uses a private faucet to issue @tech{network tokens}.

@(hrule)
@(mint-define! '("connectAccount"))
@js{
 connectAccount(networkAccount) => Promise<acc> }

Returns a Promise for a Reach @tech{account} abstraction for an existing @tech{account} for the @tech{consensus network} based on the @tech{connector}-specific @tech{account} specification provided by the @jsin{networkAccount} argument.

@js{
    // network => networkAccount type
    ETH        => ethers.Wallet
    ALGO       => {addr: string, sk: UInt8Array(64)}}

@(hrule)
@(mint-define! '("networkAccount"))
@js{
 acc.networkAccount => networkAccount }

@index{acc.networkAccount} Returns the @tech{connector}-specific @tech{account} specification of a Reach @tech{account} abstraction.

@(hrule)

@(mint-define! '("deploy"))
@js{
 acc.deploy(bin) => ctc }

@index{acc.deploy} Returns a Reach @tech{contract} abstraction after kicking off the deploy of a Reach @DApp @tech{contract} based on the @jsin{bin} argument provided.
This @jsin{bin} argument is the @filepath{input.mjs} module produced by the JavaScript @tech{backend}.
This function does not block on the completion of deployment.
To wait for deployment, see @reachin{ctc.getInfo}.

@(hrule)

@(mint-define! '("getInfo"))
@js{
 ctc.getInfo() => Promise<ctcInfo> }

@index{ctc.getInfo} Returns a Promise for an object that may be given to @jsin{attach} to construct a Reach @tech{contract} abstraction representing this contract.
This object may be stringified with @jsin{JSON.stringify} for printing and parsed again with @jsin{JSON.parse} without any loss of information.
The Promise will only be resolved after the contract is actually deployed on the network.
If you are using @reachin{{deployMode: 'firstMsg'}},
avoid blocking on this Promise with @jsin{await} until after the first @reachin{publish} has occurred.
Awaiting @reachin{getInfo} too early may cause your program to enter a state of deadlock.

@(hrule)

@(mint-define! '("attach"))
@js{
 acc.attach(bin, ctcInfoP) => ctc }

@index{acc.attach} Returns a Reach @tech{contract} abstraction based on a deployed Reach @DApp @tech{contract} provided in the @jsin{ctcInfo} argument (or a Promise for ctcInfo) and the @jsin{bin} argument.
This @jsin{bin} argument is the @filepath{input.mjs} module produced by the JavaScript @tech{backend}.

@(hrule)

@(mint-define! '("balanceOf"))
@js{
 balanceOf(acc) => Promise<amount> }

Returns a Promise for the balance of @tech{network tokens} held by the @tech{account} given by a Reach @tech{account} abstraction provided by the @jsin{acc} argument.

@(hrule)

@(mint-define! '("transfer"))
@js{
 transfer(from:acc, to:acc, amount:BigNumber) => Promise<void> }

Transfers @jsin{amount} @tech{network tokens} from @jsin{from} to @jsin{to},
which are @tech{account}s, such as those returned by @jsin{connectAccount}.
The returned Promise will only be resolved after the transfer completes.

@(hrule)

@(mint-define! '("getNetworkTime"))
@js{
 getNetworkTime() => Promise<time>
}

Returns a Promise for the current consensus network @tech{time}.
For @litchar{ETH}, @litchar{ALGO}, and @litchar{FAKE},
this is the current block number, represented as a @litchar{BigNumber}.

@(hrule)

@(mint-define! '("waitUntilTime"))
@js{
 waitUntilTime(time, onProgress) => Promise<void>
}

Returns a Promise that will only be resolved after the specified consensus network @tech{time}.
In @deftech{isolated testing modes}, which are @litchar{REACH_CONNECTOR_MODE}s
@litchar{$NET-test-dockerized-$IMPL} and @litchar{$NET-test-embedded-$IMPL}
for all valid @litchar{$NET} and @litchar{$IMPL},
this will also force time to pass on the network,
usually by sending trivial transactions.

You may provide an optional @jsin{onProgress} callback, used for reporting progress,
which may be called many times up until the specified @tech{time}.
It will receive an object with keys @jsin{currentTime} and @jsin{targetTime},

@(hrule)

@(mint-define! '("wait"))
@js{
 wait(timedelta, onProgress) => Promise<void>
}

Returns a Promise that will only be resolved after the specified @tech{time delta} has elapsed.
The expression @jsin{await wait(delta, onProgress)} is the same as
@jsin{await waitUntilTime(add(await getNetworkTime(), delta), onProgress)}.
As with @jsin{waitUntilTime}, the @jsin{onProgress} callback is optional.

@subsubsection[#:tag "ref-backend-js-stdlib-utils"]{Utilities}

@(mint-define! '("protect"))
@js{
 protect(t x) => x }

Asserts that value @jsin{x} has Reach @tech{type} @jsin{t}. An exception is thrown if this is not the case.

@(hrule)
@(mint-define! '("T_Null") '("T_Bool") '("T_UInt256") '("T_Bytes") '("T_Address") '("T_Array") '("T_Tuple") '("T_Object"))
@js{
 T_Null => ReachType
 T_Bool => ReachType
 T_UInt256 => ReachType
 T_Bytes => ReachType
 T_Digest => ReachType
 T_Address => ReachType
 T_Array(ReachType, number) => ReachType
 T_Tuple([ReachType ...]) => ReachType
 T_Object({Key: ReachType ...}) => ReachType
 T_Data({Variant: ReachType ...}) => ReachType}

Each of these represent the corresponding Reach @tech{type}.
See the table below for Reach types and their corresponding JavaScript representation:

@js{
 // Reach  => JavaScript
 Null      => null
 Bool      => 'boolean'
 UInt256   => 'BigNumber' or 'number'
 Bytes     => 'string'
 Digest    => 'BigNumber'
 Address   => 'string'
 Array     => array
 Tuple     => array
 Object    => object
 Data      => ['variant', value] }

For example, the Reach type @reachin{MInt = Data({None: Null, Some: UInt256})} inhabitant @reachin{MInt.Some(42)} is represented as @reachin{['Some', 42]} in JavaScript.

@(hrule)
@(mint-define! '("assert"))
@js{
 assert(p) }

Throws an exception if not given @jsin{true}.

@(hrule)
@(mint-define! '("Array_set"))
@js{
 Array_set(arr, idx, val) }

Returns a new array identical to @jsin{arr}, except that index @jsin{idx} is @jsin{val}.

@(hrule)
@(mint-define! '("bigNumberify") '("isBigNumber"))
@js{
 bigNumberify(x) => uint256
 isBigNumber(x) => bool}

@deftech{bigNumberify} converts a JavaScript number to a BigNumber,
the JavaScript representation of Reach's uint256.
@deftech{isBigNumber} checks if its input is a BigNumber.

@(hrule)
@(mint-define! '("toHex") '("isHex") '("hexToString") '("hexToBigNumber") '("bigNumberToHex") '("uint256ToBytes") '("bytesEq") '("digestEq") '("addressEq"))
@js{
 toHex(x) => bytes
 isHex(x) => bool
 hexToString(bytes) => string
 hexToBigNumber(bytes) => uint256
 bigNumberToHex(uint256) => bytes
 uint256ToBytes(uint256) => bytes
 bytesEq(bytes, bytes) => bool
 digestEq(Digest, Digest) => bool
 addressEq(Address, Address) => bool}

These are additional conversion and comparison utilities.

@(hrule)
@(mint-define! '("digest"))
@js{
 digest(x) => Digest}

Hashes the value.

@(hrule)
@(mint-define! '("randomUInt256"))
@js{
 randomUInt256() => uint256}

Creates 256 random bits as a uint256.

@(hrule)
@js{
 hasRandom}

A value suitable for use as a @tech{participant interact interface} requiring a @litchar{random} function.

@(hrule)
@(mint-define! '("add") '("sub") '("mod") '("mul") '("div"))
@js{
 add(uint256, uint256) => uint256
 sub(uint256, uint256) => uint256
 mod(uint256, uint256) => uint256
 mul(uint256, uint256) => uint256
 div(uint256, uint256) => uint256 }

Integer arithmetic on uint256.

@(hrule)
@(mint-define! '("eq") '("ge") '("gt") '("le") '("lt"))
@js{
 eq(uint256, uint256) => bool
 ge(uint256, uint256) => bool
 gt(uint256, uint256) => bool
 le(uint256, uint256) => bool
 lt(uint256, uint256) => bool}

Integer comparisons on uint256.

@(hrule)

The following exports are for dealing with network tokens.

@(mint-define! '("standardUnit") '("atomicUnit") '("parseCurrency") '("formatCurrency"))
@js{
 standardUnit // string
 atomicUnit // string
 parseCurrency(standardUnitAmount) => atomicUnitAmount
 formatCurrency(atomicUnitAmount, int) => string  // display amount in standard unit
}

These functions handle amounts in a network's @tech{standard unit} and its @tech{atomic unit}.
A @deftech{standard unit} is the @tech{network token} unit most commonly associated with a network.
For example, the @tech{standard unit} of Ethereum is ETH.
An @deftech{atomic unit} is the smallest unit of measure for the @tech{standard unit}.
For example, the atomic unit of Ethereum is WEI.
An @tech{atomic unit} is @deftech{atomic}, which means it cannot be divided into smaller units.

Because there are 1,000,000,000,000,000,000 WEI in 1 ETH,
BigNumber is used to represet values in WEI.

Quantities of a @tech{network token} should always be passed into Reach
in the token's @tech{atomic unit}.

@subsection[#:tag "ref-backend-js-ask.mjs"]{@tt{ask.mjs}}

This backend also provides the helper module @litchar{@"@"reach-sh/stdlib/ask.mjs} for constructing console interfaces to your @tech{frontends}.

@(mint-define! '("ask"))
@js{
  import * as ask from '@"@"reach-sh/stdlib/ask.mjs';
}

It provides the following exports:

@(mint-define! '("ask") '("yesno") '("done"))
@js{
 ask(string, (string => result)) => Promise<result>
 yesno(string) => boolean
 done() => null
}
 
@jsin{ask} is an asynchronous function that asks a question on the console and returns a Promise for the first result that its second argument does not error on.

@jsin{yesno} is an argument appropriate to give as the second argument to @jsin{ask} that parses "Yes"/"No" answers.

@jsin{done} indicates that no more questions will be asked.
