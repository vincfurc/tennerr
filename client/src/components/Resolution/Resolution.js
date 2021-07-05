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
            <Section>{disputeTabActive ? disputeTabData() : resolutionTabData()}</Section>
        </div>
    )

    function disputeTabData() {
        return <p>dispute tab</p>
    }

    function resolutionTabData() {
        return <p>resolution tab</p>;
    }

    function handleClickDisputeTab() {
        setDisputeTabActive(true);
    }

    function handleClickResolutionTab() {
        setDisputeTabActive(false);
    }
}

