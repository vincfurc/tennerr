from brownie import accounts, Contract, Tennerr, chain
from brownie.test import given, strategy
import pytest


# @given(amount=strategy('uint256', max_value=10**18))

###############
# @pytest.fixture(scope="session")
# def wMatic(interface):
#     yield interface.IwMATIC('0x2791bca1f2de4661ed88a30c99a7a9449aa84174')
###############

def testRegistration(tennerr, accounts):
    tennerr.registerSeller("vinc", "Smart contracts", "discord@vinc",{'from': accounts[0]});
    regStatus = tennerr.getSellerRegistration(accounts[0],{'from': accounts[1]})
    assert regStatus

def testRegistrationFalse(tennerr, accounts):
    tennerr.registerSeller("vinc", "Smart contracts", "discord@vinc",{'from': accounts[2]});
    regStatus = tennerr.getSellerRegistration(accounts[3],{'from': accounts[1]})
    assert regStatus == False
