import React from "react";
import Eth from "../resources/eth.svg"; // can change ot polygon

function Header() {
    return (
        <header>
            <div className="left-header">
                <div className="header-item">Overview</div>
                <div className="header-item">Validate</div>
            </div>
            <div className="right-header">
                <div className="header-item">
                    <img src={Eth} alt="eth" className="eth" />
                    Ethereum
                </div>

                <div className="connect-button">Connect</div>
            </div>
        </header>
    )
}

export default Header;