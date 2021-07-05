import React, {useState} from "react";
import {Block, Box, Content, Heading} from "react-bulma-components";

export default function Account() {
    const [walletAddress, setWalletAddress] = useState(localStorage.getItem("wallet"));
    const [username, setUserName] = useState("vinc");

    return (
        <div>
            <Box style={{width: 500, margin: 'auto'}}>
                <Block>
                    <Content>
                        <Heading>vinc</Heading>
                        <dl>
                            <dt>Wallet address</dt>
                            <dd>{walletAddress}</dd>
                            <dt>Name</dt>
                            <dd>Vitalik Buterin</dd>
                            <dt>Area</dt>
                            <dd>Earth</dd>
                            <dt>Discord</dt>
                            <dd>vinc#1920</dd>
                        </dl>
                    </Content>
                </Block>
            </Box>
        </div>
    )
}
