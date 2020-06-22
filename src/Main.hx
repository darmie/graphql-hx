package ;

import graphql.Source;
import graphql.Parser;

/**
	@author $author
**/
class Main {
	public static function main() {
		new Main();
	}

	public function new() {
		var s:Source = 
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
	
		var doc = Parser.parse(s, {
			noLocation: true
		});
		trace(doc);
	}
}