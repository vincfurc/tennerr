import detectEthereumProvider from '@metamask/detect-provider';
import {Alert, AlertIcon, Button, ButtonGroup} from "@chakra-ui/react"
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
        <p>{walletAddress ? "You are currently logged in with wallet address: " + walletAddress : "You are not currently logged in."}</p>
        {!provider ?
            <Alert status="error">
                <AlertIcon />
                Could not detect MetaMask - please install Metamask to use Tennerr
            </Alert> : null
        }
        <ButtonGroup variant="outline" spacing="6" isDisabled={!provider}>
            <Button colorScheme="blue" onClick={loginViaMetamask} isLoading={loginInProcess} isDisabled={walletAddress || !provider}>
                Login to Tennerr
            </Button>
            <Button colorScheme="blue" onClick={changeWalletSettings} isLoading={loginInProcess} >
                Change Wallet Connections
            </Button>
            <Button onClick={logoutViaMetamask}>
                Logout
            </Button>
        </ButtonGroup>
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
