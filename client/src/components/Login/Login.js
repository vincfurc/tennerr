import detectEthereumProvider from '@metamask/detect-provider';
import { Block, Button, Notification, Content } from 'react-bulma-components'
import React, { useState, useEffect } from 'react';


export default function Login() {
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
        <Button.Group variant="outline" spacing="6" isDisabled={!provider}>
            <Button color='primary' onClick={loginViaMetamask} isLoading={loginInProcess} isDisabled={walletAddress || !provider}>
                Login to Tennerr
            </Button>
            <Button color='info'onClick={changeWalletSettings} isLoading={loginInProcess} >
                Change Wallet Connections
            </Button>
            <Button color='grey-dark' onClick={logoutViaMetamask}>
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
    }
}
