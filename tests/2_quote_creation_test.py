from brownie import accounts, Contract, Tennerr, chain
from brownie.test import given, strategy
import pytest


# @given(amount=strategy('uint256', max_value=10**18))

###############
@pytest.fixture(autouse=True)
def sellerRegistration(tennerr, accounts):
    tennerr.registerSeller("vinc", "Smart contracts", "discord@vinc",{'from': accounts[0]});
    regStatus = tennerr.getSellerRegistration(accounts[0],{'from': accounts[1]})
###############



def testQuoteCreation(tennerr, accounts):
    jobId = tennerr.jobQuoteProposal(100*10**6,0,1,(1*60*60*24),0,{'from':accounts[0]})
    # tuple
    quotes = tennerr.getQuotesByAddress(accounts[0],{'from': accounts[0]})
    # array
    quote = quotes[0]
    # sellerId
    assert quote[1] == 1
