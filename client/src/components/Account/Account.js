import React, {useState} from "react";
import {Block, Content, Heading} from "react-bulma-components";

export default function Account() {
    const [walletAddress, setWalletAddress] = useState(localStorage.getItem("wallet"));

    return (
        <div>
            <Block>
                <Content>
                    <Heading>vinc</Heading>
                    <p>{walletAddress ? "Wallet address: " + walletAddress : "You are not currently logged in."}</p>
                </Content>
            </Block>
        </div>
    )
}
