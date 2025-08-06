import type { JSX } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

export default function ProtectedRoute({ children }: { children: JSX.Element }) {
    const { user } = useAuth();
    if (user) {
        return children;
    } else {
        return <Navigate to="/login" replace />
    }
};