# GraphQL

## A set of tools for using GraphQL in Haxe and target programming languages / runtime.

### Dependencies

 * [Haxe](https://haxe.org/)
 * [Node.js](https://nodejs.org/)
 * [hxnodejs](https://lib.haxe.org/p/hxnodejs)
 * [Neko](https://nekovm.org)
 * [HashLink](https://hashlink.haxe.org)
 * [hxjava](https://lib.haxe.org/p/hxjava)
 * [hxcpp](https://lib.haxe.org/p/hxcpp)
 * [hxcs](https://lib.haxe.org/p/hxcs)

This project uses [lix.pm](https://github.com/lix-pm/lix.client) as Haxe package manager.
Run `npm install` to install the dependencies.


## Usage 

### Parsing GraphQL source to AST


```hx
import graphql.Parser;
import graphql.Source;

var s:Source = 
	'type Query{
		user:User @isAuthenticated
		getCurrencies:[Currency!]!
		getCountries:[Country!]!
		userTransactions(walletID: ID!):[WalletAccountingEntry] @isAuthenticated
		transactionsAggregate(startDate:DateTime, endDate:DateTime):[Transaction] @isAuthenticated
		getUserWallets:[Wallet!]! @isAuthenticated
		getBalance(userID:ID!, walletID:ID!):BalanceResult @isAuthenticated
	}';
	
var doc = Parser.parse(s, {
			noLocation: true
});
trace(doc);
```

### Compile js

```
npm run haxe build-js.hxml
```

### Compile nodejs

```
npm run haxe build-nodejs.hxml
node bin/GraphQL.js
```

### Compile python

```
npm run haxe build-python.hxml
python bin/GraphQL.py
```

### Compile swf

```
npm run haxe build-swf.hxml
run bin/GraphQL.swf
```

### Compile as3

```
npm run haxe build-as3.hxml
```

### Compile lua

```
npm run haxe build-lua.hxml
```

### Compile php7

```
npm run haxe build-php7.hxml
```

### Compile neko

```
npm run haxe build-neko.hxml
npm run neko bin/GraphQL.n
```

### Compile hl

```
npm run haxe build-hl.hxml
hl bin/GraphQL.hl
```

### Compile php

```
npm run haxe build-php.hxml
php bin/GraphQL
```

### Compile java

```
npm run haxe build-java.hxml
java -jar bin/GraphQL.jar
```

### Compile cpp

```
npm run haxe build-cpp.hxml
```

### Compile cs

```
npm run haxe build-cs.hxml
bin/GraphQL/bin/Main.exe
```

