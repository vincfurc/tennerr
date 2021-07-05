import React, {useState} from 'react'
import {Section, Tabs} from "react-bulma-components";

export default function Resolution() {
    const [disputeTabActive, setDisputeTabActive] = useState(true);

    return (
        <Tabs>
            <Tabs.Tab className={disputeTabActive? 'is-active': ''} onClick={handleClickDisputeTab}>
                My Disputes
            </Tabs.Tab>
            <Tabs.Tab className={!disputeTabActive? 'is-active': ''} onClick={handleClickResolutionTab}>
                My Resolutions
            </Tabs.Tab>
        </Tabs>
    )

    function handleClickDisputeTab() {
        setDisputeTabActive(true);
    }

    function handleClickResolutionTab() {
        setDisputeTabActive(false);
    }
}

