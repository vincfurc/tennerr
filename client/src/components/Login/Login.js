import detectEthereumProvider from '@metamask/detect-provider';
import { Block, Button, Notification, Content } from 'react-bulma-components'
import React, { useState, useEffect } from 'react';


export default function Login( props ) {
    const [loginInProcess, setLoginInProcess] = useState(false);
    const [walletAddress, setWalletAddress] = useState(localStorage.getItem("wallet"));
    const [provider, setProvider] = useState(null);

    useEffect(() => {
        detectEthereumProvider()
            .then((provider) => {
                setProvider(provider);
                if (provider != null) {
                    provider.on('accountsChanged', function (accounts) {
                        handleAccountsChanged(accounts);
                    });
                }
            })
    },[provider]);

    function handleAccountsChanged(accounts) {
        if (accounts.length === 0) {
            logoutViaMetamask();
        } else if (accounts[0] !== walletAddress) {
            setWalletAddress(accounts);
            localStorage.setItem("wallet", accounts);
        }
    }

    return <div>
            <Block>
                <Content>
                    <p>{walletAddress ? "You are currently logged in with wallet address: " + walletAddress : "You are not currently logged in."}</p>
                </Content>
            </Block>
        {!provider ?
            <Block>
                <Notification color='warning'>
                    <Content>
                        <p>
                        Could not detect MetaMask - please install Metamask to use Tennerr!
                        </p>
                    </Content>
                </Notification>
            </Block> : null
        }
        <Button.Group align='center'>
            <Button color='primary' onClick={loginViaMetamask} loading={loginInProcess} disabled={walletAddress || !provider} inverted >
                Login to Tennerr
            </Button>
            <Button color='info'onClick={changeWalletSettings} loading={loginInProcess} disabled={!provider} inverted >
                Change Wallet Connections
            </Button>
            <Button color='grey-dark' onClick={logoutViaMetamask} disabled={!provider} >
                Logout
            </Button>
        </Button.Group>
    </div>;

    function loginViaMetamask(e) {
        setLoginInProcess(true);
        provider.request({
            method: 'eth_requestAccounts'
        }).then(handleAccountsChanged).catch((e) => {
            logoutViaMetamask();
            console.error(e);
        }).finally(() => {
            setLoginInProcess(false);
            props.user(walletAddress);
        });
    }

    function changeWalletSettings(e) {
        setLoginInProcess(true)
        provider.request({
            method: "wallet_requestPermissions",
            params: [{
                eth_accounts: {}
            }]
        }).then((permission) => {})
            .finally(() => {
            setLoginInProcess(false);
        });
    }

    function logoutViaMetamask() {
        localStorage.setItem("wallet", "");
        setWalletAddress("");
        props.user(walletAddress);
    }
}
