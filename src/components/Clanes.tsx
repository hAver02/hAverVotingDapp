// components/ClanSection.tsx
import React, { useEffect } from 'react';

export interface Clan {
    id: number;
    name: string;
    leader: string;
    members: string[];
    lastVoteTime: number;
    lastVoteEndTime: number;
}
interface ClanSectionProps {
  clanes: Clan[];
//   onSelectClan: (clanId: number) => void;
    contract : any
}

const Clanes: React.FC<ClanSectionProps> = ({ contract, clanes }) => {
    return (
        <div className="p-4 border-r border-gray-300">
            <h2 className="text-xl font-bold mb-4 text-center text-black ">CLANES</h2>
            <ul>
                {clanes.map((clan) => (
                <li key={clan.id} className="cursor-pointer p-2 mb-2 bg-gray-100 rounded hover:bg-gray-200 text-blue-700
                     flex flex-col gap-2 items-center justify-center" >
                        <span>
                            {clan.name} 
                        </span>
                        <span>
                            Leader: {`${clan.leader.slice(0,4)} ... ${clan.leader.slice(28,32)}`}
                        </span>
                </li>
                ))}
            </ul>
        </div>
    );
};

export default Clanes;