from brownie import accounts, Contract, Tennerr, chain
from brownie.test import given, strategy
import pytest


# @given(amount=strategy('uint256', max_value=10**18))

###############
@pytest.fixture(autouse=True)
def sellerRegistration(tennerr, accounts):
    tennerr.registerSeller("vinc", "Smart contracts", "discord@vinc",{'from': accounts[0]});
    regStatus = tennerr.getSellerRegistration(accounts[0],{'from': accounts[1]})
    # create quote
    jobId = tennerr.jobQuoteProposal(100*10**6,0,1,(1*60*60*24),0,{'from':accounts[0]})
    # superfluid payment
    jobId2 = tennerr.jobQuoteProposal(100*10**6,2,1,(1*60*60*24),386,{'from':accounts[0]})

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
            "from": accounts[1],
            'value': "99 ether"
        }
    )

# @pytest.fixture(autouse=True)
# def tennerrStreamer(TennerrStreamer, accounts):
#     yield TennerrStreamer.deploy(  host,
#          cfa,
#          acceptedToken,
#          receiver) # escrow
#     {'from': accounts[0]})

@pytest.fixture(autouse=True)
def def_setters(tennerr, tennerrController,tennerrEscrow,tennerrFactory,tennerrFactoryX,tennerrStreamer,tennerrDAO, accounts):
    tennerr.setTennerrController(tennerrController,{'from': accounts[0]})
    tennerr.setTennerrEscrow(tennerrEscrow,{'from': accounts[0]})
    tennerr.setTennerrFactory(tennerrFactory,{'from': accounts[0]})
    tennerr.setTennerrFactoryX(tennerrFactoryX,{'from': accounts[0]})
    tennerr.setTennerrStreamer(tennerrStreamer,{'from': accounts[0]})
    tennerrEscrow.setTennerr(tennerr,{'from':accounts[0]})
    tennerrEscrow.setTennerrStreamer(tennerrStreamer,{'from':accounts[0]})
    tennerrFactory.setTennerr(tennerr,{'from': accounts[0]})
    tennerrFactory.setTennerrController(tennerrController,{'from': accounts[0]})
    tennerrController.setAaveLendingPoolAddress('0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf',{'from':accounts[0]})
    tennerrController.setAaveDataProviderAddress('0x7551b5D2763519d4e37e8B81929D336De671d46d',{'from':accounts[0]})
    tennerrStreamer.setTennerrEscrow(tennerrEscrow,{'from': accounts[0]})
    tennerrStreamer.setTennerr(tennerr,{'from': accounts[0]})
    tennerrDAO.setTennerrEscrow(tennerrEscrow,{'from': accounts[0]} )
    tennerrEscrow.setTennerrDAO(tennerrDAO,{'from': accounts[0]})


###############

def testPaymentFunction_0(tennerr, accounts, interface,usdc, tennerrController, tennerrFactory, tennerrEscrow):
    # tuple
    quotes = tennerr.getQuotesByAddress(accounts[0],{'from': accounts[0]})
    # array
    quote = quotes[0]
    quoteId = quote[0]
    usdc.approve(tennerr,100*10**6,{'from':accounts[2]})
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[2]})
    cTNR = interface.IERC20Minimal(tennerrFactory);
    aaveFX = tennerrController.getExchangeRate(0,"USDC",{'from':accounts[2]}).return_value
    amountMinted = (100*10**6*10**27/aaveFX)
    assert amountMinted>0
    assert cTNR.balanceOf(tennerrEscrow, {'from': accounts[0] }) > 0

def testPaymentFunction_2(tennerr, accounts, interface,usdc, tennerrController, tennerrFactory, tennerrEscrow,tennerrFactoryX, tennerrStreamer):
    # tuple
    quotes = tennerr.getQuotesByAddress(accounts[0],{'from': accounts[0]})
    # array
    quote = quotes[1]
    quoteId = quote[0]
    # print(quotes[0],quotes[1])
    # payment type is superfluid
    assert quote[3] == 2
    # print(tennerr.getQuoteByQuoteId(quoteId))
    usdc.approve(tennerr,100*10**6,{'from':accounts[2]})
    cTNR = interface.IERC20Minimal(tennerrFactory);
    assert cTNR.balanceOf(tennerrEscrow, {'from': accounts[0] }) == 0
    tennerr.paySeller(quoteId,100*10**6,"USDC",{'from':accounts[2]})
    chain.sleep(1)
    chain.mine(1)
    # tennerrStreamer.accountingCache(quoteId,386,{'from': tennerrEscrow})
    # x = tennerrStreamer.getStreamData(quoteId,{'from': accounts[0]})
    # print(x)
    cTNRx = interface.ISuperToken(tennerrFactoryX);
    assert cTNRx.balanceOf(tennerrEscrow, {'from': accounts[0] })> 0
    data = tennerrStreamer.getStreamData(quoteId)
    assert cTNRx.balanceOf(tennerrEscrow, {'from': accounts[0] }) == data[1]
