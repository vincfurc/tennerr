from brownie import accounts, Contract, Tennerr, chain
from brownie.test import given, strategy
import pytest


# @given(amount=strategy('uint256', max_value=10**18))

###############
@pytest.fixture(autouse=True)
def sellerRegistration(tennerr, accounts):
    tennerr.registerSeller("vinc", "Smart contracts", "discord@vinc",{'from': accounts[0]});
    regStatus = tennerr.getSellerRegistration(accounts[0],{'from': accounts[1]})
    tennerr.registerSeller("vinc", "Smart contracts", "discord@vinc",{'from': accounts[1]});
    tennerr.registerSeller("vinc", "Smart contracts", "discord@vinc",{'from': accounts[4]});
    tennerr.registerSeller("vinc", "Smart contracts", "discord@vinc",{'from': accounts[6]});

    # create quot
    jobId = tennerr.jobQuoteProposal(100*10**6,0,1,(1*60*60*24),0,{'from':accounts[0]}).return_value

# get usdc
@pytest.fixture(scope="session")
def usdc(interface):
    yield interface.IERC20Minimal('0x2791bca1f2de4661ed88a30c99a7a9449aa84174')

@pytest.fixture(scope="session")
def uniswap_usdc_exchange(interface):
    yield interface.IUniswapV2Exchange('0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff')

@pytest.fixture(autouse=True)
def buy_usdc(accounts, usdc,uniswap_usdc_exchange):
    dev = accounts.at('0x474bafA6db6C7c452422Ff30C60538FecE385332',force=True)
    uniswap_usdc_exchange.swapExactETHForTokens(
        1,  # minimum amount of tokens to purchase
        ['0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270','0x2791bca1f2de4661ed88a30c99a7a9449aa84174'],
        accounts[2],
        9999999999,  # timestamp
        {
            "from": accounts[2],
            'value': "99 ether"
        }
    )
    uniswap_usdc_exchange.swapExactETHForTokens(
        1,  # minimum amount of tokens to purchase
        ['0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270','0x2791bca1f2de4661ed88a30c99a7a9449aa84174'],
        accounts[3],
        9999999999,  # timestamp
        {
            "from": accounts[3],
            'value': "99 ether"
        }
    )
    uniswap_usdc_exchange.swapExactETHForTokens(
        1,  # minimum amount of tokens to purchase
        ['0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270','0x2791bca1f2de4661ed88a30c99a7a9449aa84174'],
        accounts[5],
        9999999999,  # timestamp
        {
            "from": accounts[5],
            'value': "99 ether"
        }
    )
    uniswap_usdc_exchange.swapExactETHForTokens(
        1,  # minimum amount of tokens to purchase
        ['0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270','0x2791bca1f2de4661ed88a30c99a7a9449aa84174'],
        accounts[7],
        9999999999,  # timestamp
        {
            "from": accounts[7],
            'value': "99 ether"
        }
    )


@pytest.fixture(autouse=True)
def def_setters(tennerr, tennerrController,tennerrEscrow,tennerrFactory,tennerrVotingRightsToken,tennerrDAO, accounts):
    tennerr.setTennerrController(tennerrController,{'from': accounts[0]})
    tennerr.setTennerrEscrow(tennerrEscrow,{'from': accounts[0]})
    tennerr.setTennerrFactory(tennerrFactory,{'from': accounts[0]})
    tennerr.setTennerrDAO(tennerrDAO,{'from': accounts[0]})
    tennerrEscrow.setTennerr(tennerr,{'from':accounts[0]})
    tennerrEscrow.setTennerrFactory(tennerrFactory,{'from': accounts[0]})
    tennerrEscrow.setTennerrDAO(tennerrDAO,{'from': accounts[0]})
    tennerrFactory.setTennerr(tennerr,{'from': accounts[0]})
    tennerrFactory.setTennerrController(tennerrController,{'from': accounts[0]})
    tennerrController.setAaveLendingPoolAddress('0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf',{'from':accounts[0]})
    tennerrController.setAaveDataProviderAddress('0x7551b5D2763519d4e37e8B81929D336De671d46d',{'from':accounts[0]})
    tennerrDAO.setTennerr(tennerr,{'from': accounts[0]} )
    tennerrDAO.setTennerrVRT(tennerrVotingRightsToken,{'from': accounts[0]} )
    tennerrDAO.setTennerrEscrow(tennerrEscrow,{'from': accounts[0]} )
    tennerrVotingRightsToken.setTennerrDAO(tennerrDAO,{'from': accounts[0]})
###############

def testTimeExtension(tennerr,tennerrEscrow, accounts,tennerrDAO, usdc):
    # tuple
    quotes = tennerr.getQuotesByAddress(accounts[0],{'from': accounts[0]})
    # array
    quote = quotes[0]
    quoteId = quote[0]
    usdc.approve(tennerr,100*10**6,{'from':accounts[2]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[2]})
    quoteNew = tennerrEscrow.getQuoteData(quoteId)
    initialDeadline = quoteNew[6]
    # print(initialDeadline)
    # x = tennerrDAO.disputeJob(quoteId,accounts[2],accounts[0], 1 )
    tennerr.openDispute( quoteId, 1, {'from':accounts[2]}).return_value
    tennerr.sellerAppeal(quoteId,1, 60*60*48, "Need a little more time, will be done in 48h.", {'from': accounts[0]})
    tennerr.buyerAppealResponse(quoteId,0, 0, "Ok.", {'from': accounts[2]})
    quoteNew = tennerrEscrow.getQuoteData(quoteId)
    # adding time from now not from original timeline
    assert quoteNew[6] == chain.time() + (60*60*48)


def testIncreaseCompensation(tennerr,tennerrEscrow, accounts,tennerrDAO, usdc):
    # tuple
    quotes = tennerr.getQuotesByAddress(accounts[0],{'from': accounts[0]})
    # array
    quote = quotes[0]
    quoteId = quote[0]
    usdc.approve(tennerr,100*10**6,{'from':accounts[2]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[2]})
    quoteNew = tennerrEscrow.getQuoteData(quoteId)
    initialPrice = quoteNew[5]
    # x = tennerrDAO.disputeJob(quoteId,accounts[2],accounts[0], 1 )
    tennerr.openDispute( quoteId, 1, {'from':accounts[2]}).return_value
    tennerr.sellerAppeal(quoteId,2, 100*10**6, "Job is more complex than expected.", {'from': accounts[0]})
    tennerr.buyerAppealResponse(quoteId,0, 0, "Ok.", {'from': accounts[2]})
    quoteNew = tennerrEscrow.getQuoteData(quoteId)
    assert quoteNew[5] == initialPrice + 100*10**6

def testRefund(tennerr, tennerrEscrow,tennerrDAO, tennerrFactoryX, accounts, usdc, interface ):
    # tuple
    quotes = tennerr.getQuotesByAddress(accounts[0],{'from': accounts[0]})
    # array
    quote = quotes[0]
    quoteId = quote[0]
    usdc.approve(tennerr,100*10**6,{'from':accounts[2]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[2]})
    # x = tennerrDAO.disputeJob(quoteId,accounts[2],accounts[0], 1 )
    tennerr.openDispute( quoteId, 1, {'from':accounts[2]}).return_value
    tennerr.sellerAppeal(quoteId,0, 0, "Can't do it, I offer you a refund.", {'from': accounts[0]})
    tennerr.buyerAppealResponse(quoteId,0, 0, "Ok.", {'from': accounts[2]})
    assert interface.IERC20(tennerrFactoryX).balanceOf(tennerrEscrow) == 0;

@pytest.mark.skip(reason="To implement properly")
def testVotersElection(tennerr, tennerrEscrow,tennerrFactoryX,tennerrFactory,tennerrDAO, tennerrVotingRightsToken,accounts, interface,usdc):
    # print(tennerrDAO.expand(4,2))
    # print(tennerrDAO._modValues([37470079394597546017821359402343014298469527652371950473243809108734949064165,
    #     107553882524790531947385985832592837884442228935463780553192851707863573624387],2))
    # tuple
    quotes = tennerr.getQuotesByAddress(accounts[0],{'from': accounts[0]})
    # array
    quote = quotes[0]
    quoteId = quote[0]
    usdc.approve(tennerr,100*10**6,{'from':accounts[2]})
    usdc.approve(tennerr,100*10**6,{'from':accounts[3]})
    usdc.approve(tennerr,100*10**6,{'from':accounts[5]})
    usdc.approve(tennerr,100*10**6,{'from':accounts[7]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[3]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[5]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[7]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[2]})

    # print(quotes)
    # print(quoteId)
    # x = tennerrDAO.disputeJob(quoteId,accounts[2],accounts[0], 1 )
    tennerr.openDispute( quoteId, 1, {'from':accounts[2]}).return_value
    tennerr.sellerAppeal(quoteId,1, 0, "Can't do it need more time", {'from': accounts[0]})
    tennerr.buyerAppealResponse(quoteId,4, 0, "NO.Give me a refund.", {'from': accounts[2]})
    tennerr.sellerDealResponse(quoteId, 1, "Then let DAO decide",{'from': accounts[0]})

    values = tennerrDAO.expand(3,7)
    newValues = tennerrDAO._modValues(values,7).return_value
    elected = tennerrDAO._electVoters(newValues, quoteId,{'from':accounts[0]}).return_value
    # tennerrVotingRightsToken.issueMulti(elected,{'from':tennerrDAO})
    # assert interface.IERC20(tennerrVotingRightsToken).balanceOf(elected[1])>0
    tennerrDAO.electVoters(quoteId,{'from': accounts[0]})
    assert interface.IERC20(tennerrVotingRightsToken).balanceOf(elected[1])>0
    assert interface.IERC20(tennerrFactoryX).balanceOf(elected[1])==0;
    cTNRx = interface.ISuperToken(tennerrFactoryX);
    VTR = interface.IERC20(tennerrVotingRightsToken)
    interface.IERC20(tennerrFactory).approve(tennerrFactoryX, 100*10**6,{'from':tennerrEscrow});
    transferAmount = 12*10**6*10**18/10**6
    cTNRx.upgrade(transferAmount,{'from':tennerrEscrow})
    cTNRx.transfer(accounts[0],transferAmount,{'from':tennerrEscrow});
    assert cTNRx.balanceOf(accounts[0], {'from': accounts[0] })> 0
    balance = cTNRx.balanceOf(accounts[0])
    cTNRx.approve(tennerrVotingRightsToken,balance,{'from': accounts[0]})
    # agg = interface.IInstantDistributionAgreementV1('0x5a12492d7D6A61DecbC9579eAF5e6baEf3329a91')
    # print(agg.getIndex(tennerrVotingRightsToken,accounts[0],0,{'from':accounts[0]}))
    print(balance)
    tennerrVotingRightsToken.distribute(7*10**18,{'from':accounts[0]})
    print(accounts[0])
    print(cTNRx.balanceOf(elected[0]))
    print(VTR.balanceOf(elected[0]))
    print(elected[0])
    print(cTNRx.balanceOf(elected[1]))
    print(VTR.balanceOf(elected[1]))
    print(elected[1])
    print(cTNRx.balanceOf(elected[2]))
    print(VTR.balanceOf(elected[2]))
    print(elected[2])
    print(cTNRx.balanceOf(elected[3]))
    print(VTR.balanceOf(elected[3]))
    print(elected[3])
    print(cTNRx.balanceOf(elected[4]))
    print(VTR.balanceOf(elected[4]))
    print(elected[4])
    print(cTNRx.balanceOf(elected[5]))
    print(VTR.balanceOf(elected[5]))
    print(elected[5])
    print(cTNRx.balanceOf(elected[6]))
    print(VTR.balanceOf(elected[6]))
    print(elected[6])

    assert interface.IERC20(tennerrFactoryX).balanceOf(tennerrVotingRightsToken)==0;
    assert interface.IERC20(tennerrFactoryX).balanceOf(elected[2])>0;


def testVotersVotingAndResolution(tennerr, tennerrEscrow,tennerrFactoryX,tennerrFactory,tennerrDAO, tennerrVotingRightsToken,accounts, interface,usdc):
    # print(tennerrDAO.expand(4,2))
    # print(tennerrDAO._modValues([37470079394597546017821359402343014298469527652371950473243809108734949064165,
    #     107553882524790531947385985832592837884442228935463780553192851707863573624387],2))
    # tuple
    quotes = tennerr.getQuotesByAddress(accounts[0],{'from': accounts[0]})
    # array
    quote = quotes[0]
    quoteId = quote[0]
    usdc.approve(tennerr,100*10**6,{'from':accounts[2]})
    usdc.approve(tennerr,100*10**6,{'from':accounts[3]})
    usdc.approve(tennerr,100*10**6,{'from':accounts[5]})
    usdc.approve(tennerr,100*10**6,{'from':accounts[7]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[3]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[5]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[7]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[2]})

    # print(quotes)
    # print(quoteId)
    # x = tennerrDAO.disputeJob(quoteId,accounts[2],accounts[0], 1 )
    tennerr.openDispute( quoteId, 1, {'from':accounts[2]}).return_value
    tennerr.sellerAppeal(quoteId,1, 0, "Can't do it need more time", {'from': accounts[0]})
    tennerr.buyerAppealResponse(quoteId,4, 0, "NO.Give me a refund.", {'from': accounts[2]})
    tennerr.sellerDealResponse(quoteId, 1, "Then let DAO decide",{'from': accounts[0]})

    values = tennerrDAO.expand(3,7)
    newValues = tennerrDAO._modValues(values,7).return_value
    elected = tennerrDAO._electVoters(newValues, quoteId,{'from':accounts[0]}).return_value
    # tennerrVotingRightsToken.issueMulti(elected,{'from':tennerrDAO})
    # assert interface.IERC20(tennerrVotingRightsToken).balanceOf(elected[1])>0
    tennerrDAO.electVoters(quoteId,{'from': accounts[0]})
    tennerrDAO.voteOnDispute(quoteId,2,{'from': elected[0]})
    tennerrDAO.voteOnDispute(quoteId,2,{'from': elected[2]})
    chain.sleep(999999999999999)
    chain.mine(1)
    winner = tennerrDAO.getDisputeDecision(quoteId,{'from': accounts[0]}).return_value
    print(winner)
    tennerrDAO.executeDisputeDecision(quoteId,{'from': accounts[0]})
