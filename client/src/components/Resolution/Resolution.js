import React, {useState} from 'react'
import {Card, Content, Heading, Image, Media, Section, Tabs} from "react-bulma-components";

export default function Resolution() {
    const [disputeTabActive, setDisputeTabActive] = useState(true);

    return (
        <div>
            <Tabs>
                <Tabs.Tab className={disputeTabActive? 'is-active': ''} onClick={handleClickDisputeTab}>
                    My Disputes
                </Tabs.Tab>
                <Tabs.Tab className={!disputeTabActive? 'is-active': ''} onClick={handleClickResolutionTab}>
                    My Resolutions
                </Tabs.Tab>
            </Tabs>
            {disputeTabActive ? disputeTabData() : resolutionTabData()}
        </div>
    )

    function disputeTabData() {
        return <Card>
            <Card.Content>
                <Media>
                    <Media.Item renderAs="figure" position="left">
                        <Image
                            size={64}
                            alt="64x64"
                            src="./assets/images/ukulele.jpg"
                        />
                    </Media.Item>
                    <Media.Item>
                        <Heading size={4}>musicman</Heading>
                        <Heading subtitle size={6}>
                            @musicman#1234
                        </Heading>
                    </Media.Item>
                </Media>
                <Content>
                    <p><strong>Original Request:</strong> I need someone to play some music for our 4th of july party</p>
                    <p><strong>Dispute Information:</strong> no show</p>
                    <p><strong>Payment:</strong> 0.090 Eth</p>
                    <time dateTime="2021-07-04">9:48 PM - 4 Jul 2021</time>
                </Content>
            </Card.Content>
            <Card.Footer>
                <Card.Footer.Item>
                    Current Status: <a href="#ResolutonDetails">Pending Resolution</a>
                </Card.Footer.Item>
            </Card.Footer>
        </Card>;
    }

    function resolutionTabData() {
        return <Card>
            <Card.Content>
                <Media>
                    <Media.Item renderAs="figure" position="left">
                        <Image
                            size={64}
                            alt="64x64"
                            src="https://cdn.discordapp.com/avatars/231822195871973376/6df32e924eb3fb95024204c58c4b86fd.png?size=128"
                        />
                    </Media.Item>
                    <Media.Item>
                        <Heading size={4}>iso</Heading>
                        <Heading subtitle size={6}>
                            @iso#0001
                        </Heading>
                    </Media.Item>
                </Media>
                <Content>
                    <p><strong>Original Request:</strong> can someone knit christmas hats for my cats</p>
                    <p><strong>Dispute Information:</strong> wigglesworth doesnt like the green hat</p>
                    <img src="./assets/images/christmas-cats.jpg"/>
                    <p><strong>Payment:</strong> 0.0068 Eth</p>
                    <time dateTime="2020-12-24">3:23 PM - 24 Dec 2020</time>
                </Content>
            </Card.Content>
            <Card.Footer>
                <Card.Footer.Item>
                    Current Status: <a href="#ResolutonDetails">Resolved in favor of @vinc</a>
                </Card.Footer.Item>
            </Card.Footer>
        </Card>;
    }

    function handleClickDisputeTab() {
        setDisputeTabActive(true);
    }

    function handleClickResolutionTab() {
        setDisputeTabActive(false);
    }
}

