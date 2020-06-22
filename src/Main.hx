package ;

import graphql.Source;
using graphql.Parser;

/**
	@author $author
**/
class Main {
	public static function main() {
		new Main();
	}

	public function new() {
		var gql:Source = 
			'type Query{
				user:User @isAuthenticated
				cardPin(cardID:ID!):CardPinView!
				card(publicToken:String!, cardHolder:ID!, isDiscarded:Boolean):Card!
				getCurrencies:[Currency!]!
				getCountries:[Country!]!
				userTransactions(walletID: ID!):[WalletAccountingEntry] @isAuthenticated
				transactionsAggregate(startDate:DateTime, endDate:DateTime):[Transaction] @isAuthenticated
				getUserWallets:[Wallet!]! @isAuthenticated
				getBalance(userID:ID!, walletID:ID!):BalanceResult @isAuthenticated
			}';
		
		var document = gql.parse({noLocation: true});
		trace(document);
	}
}