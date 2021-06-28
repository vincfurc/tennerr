import detectEthereumProvider from '@metamask/detect-provider';

export default function Login() {
    return <div>
        <h2>Login Page</h2>
        <p>You are not currently logged in.</p>
        <div>
            <button onClick={loginViaMetamask}>
                Click here to login/print connected MetaMask account to console
            </button>
        </div>
        <div>
            <button onClick={logoutViaMetamask}>
                Click here to logout/choose a different MetaMask account
            </button>
        </div>
    </div>;
}

async function loginViaMetamask() {
    const provider = await detectEthereumProvider();
    if (!provider) {
        console.log('Please install MetaMask!');
        return;
    }

    console.log('Ethereum successfully detected!')
    // var accounts = await provider.eth.getAccounts();
    // console.log("accounts: " + accounts)
    try {
        // Will open the MetaMask UI
        // TODO You should disable this button while the request is pending!
        const accounts = await provider.request({ method: 'eth_requestAccounts',
            params: [{
                eth_accounts: {}
            }]
        });
        console.log(accounts)
    } catch (error) {
        console.error(error);
    }
}

async function getWalletAddress() {
    const provider = await detectEthereumProvider();
    if (!provider) {
        console.log('Please install MetaMask!');
        return;
    }

    const accounts = await provider.request({ method: 'eth_accounts'});
    console.log("detected accounts: " + accounts)
    return accounts;
}

async function logoutViaMetamask() {
    const provider = await detectEthereumProvider();
    if (!provider) {
        console.log('Please install MetaMask!');
        return;
    }

    console.log("Popping up MetaMask so user can change their wallet settings...")
    await provider.request({
        method: "wallet_requestPermissions",
        params: [{
            eth_accounts: {}
        }]
    });
}
